import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum VibeIceState { checking, connected, failed, reconnecting, disconnected }

class VibeWebRTCService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  String? _roomId;
  String? _uid;
  bool _isCaller = false;
  bool isVideo = false;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // Streams for UI (Recreated in init to support re-initialization)
  StreamController<VibeIceState>? _iceStateController;
  Stream<VibeIceState> get iceStateStream => _iceStateController?.stream ?? const Stream.empty();
  
  StreamController<double>? _audioLevelController;
  Stream<double> get localAudioLevelStream => _audioLevelController?.stream ?? const Stream.empty();
  
  StreamController<double>? _remoteAudioLevelController;
  Stream<double> get remoteAudioLevelStream => _remoteAudioLevelController?.stream ?? const Stream.empty();
  
  StreamController<VibeQualityState>? _qualityController;
  Stream<VibeQualityState> get qualityStream => _qualityController?.stream ?? const Stream.empty();

  Function(MediaStream stream)? onRemoteStreamAdd;
  Timer? _statsTimer;
  final List<RTCIceCandidate> _remoteCandidatesQueue = [];

  // ICE Configuration with TURN fallback
  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turns:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ],
    'iceCandidatePoolSize': 10,
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'sdpSemantics': 'unified-plan',
  };

  Future<void> init(String roomId, String uid, bool isCaller, bool isVideo) async {
    _roomId = roomId;
    _uid = uid;
    _isCaller = isCaller;
    this.isVideo = isVideo;
    
    // Initialize/Recreate controllers
    _iceStateController = StreamController<VibeIceState>.broadcast();
    _audioLevelController = StreamController<double>.broadcast();
    _remoteAudioLevelController = StreamController<double>.broadcast();
    _qualityController = StreamController<VibeQualityState>.broadcast();

    _peerConnection = await createPeerConnection({
      ..._iceConfig,
      'dtlsSrtpKeyAgreement': true, // Explicit DTLS-SRTP
    });

    _peerConnection?.onIceConnectionState = (state) {
      
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateChecking:
          _safeAdd(_iceStateController, VibeIceState.checking);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _safeAdd(_iceStateController, VibeIceState.connected);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _safeAdd(_iceStateController, VibeIceState.failed);
          _handleIceFailure();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _safeAdd(_iceStateController, VibeIceState.disconnected);
          break;
        default:
          break;
      }
    };

    _peerConnection?.onIceCandidate = (candidate) {
      if (_roomId != null) {
        final String collection = isCaller ? 'callerCandidates' : 'calleeCandidates';
        _db.collection('vibetalk_rooms').doc(_roomId).collection(collection).add(candidate.toMap());
      }
    };

    _peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        _remoteStream = stream;
        onRemoteStreamAdd?.call(stream);
      }
    };

    // Enhanced Audio Constraints
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 48000,
        'channelCount': 1,
      },
      'video': isVideo ? {
        'facingMode': 'user',
        'width': 1280,
        'height': 720,
      } : false,
    };
    
    try {
      final localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = localStream;
      localStream.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, localStream);
      });
    } catch (e) {
      
    }

    if (isCaller) {
      await _createOffer();
    } else {
      await _listenForOffer();
    }

    _listenForRemoteIceCandidates(isCaller);
    _startStatsMonitoring();
  }

  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_peerConnection == null) return;
      
      final stats = await _peerConnection!.getStats();
      double localLevel = 0;
      double remoteLevel = 0;
      
      for (final report in stats) {
        if (report.type == 'media-source' && report.values['kind'] == 'audio') {
          localLevel = (report.values['audioLevel'] ?? 0.0).toDouble();
        }
        if (report.type == 'inbound-rtp' && report.values['kind'] == 'audio') {
          remoteLevel = (report.values['audioLevel'] ?? 0.0).toDouble();
          
          // Quality Logic (every 3s roughly via counter or just here)
          if (timer.tick % 6 == 0) {
            _updateQuality(report);
          }
        }
      }
      
      _safeAdd(_audioLevelController, localLevel);
      _safeAdd(_remoteAudioLevelController, remoteLevel);
    });
  }

  void _safeAdd<T>(StreamController<T>? controller, T value) {
    if (controller != null && !controller.isClosed) {
      controller.add(value);
    }
  }

  void _updateQuality(StatsReport report) {
    final rtt = (report.values['roundTripTime'] ?? 0.0).toDouble() * 1000;
    final packetsLost = (report.values['packetsLost'] ?? 0).toInt();
    final packetsSent = (report.values['packetsReceived'] ?? 1).toInt(); // Approximate
    final lossRatio = packetsSent > 0 ? (packetsLost / (packetsSent + packetsLost)) : 0.0;

    VibeQualityState quality;
    if (rtt < 100 && lossRatio < 0.01) {
      quality = VibeQualityState.excellent;
    } else if (rtt < 200 && lossRatio < 0.03) {
      quality = VibeQualityState.good;
    } else if (rtt < 400 && lossRatio < 0.08) {
      quality = VibeQualityState.fair;
    } else {
      quality = VibeQualityState.poor;
      _degradeBitrate();
    }
    
    _safeAdd(_qualityController, quality);
  }

  Future<void> _degradeBitrate() async {
    final pc = _peerConnection;
    if (pc == null) return;
    
    final senders = await pc.getSenders();
    for (final sender in senders) {
      if (sender.track?.kind == 'audio') {
        final params = sender.parameters;
        if (params.encodings != null && params.encodings!.isNotEmpty) {
          params.encodings!.first.maxBitrate = 24000; // 24kbps
          await sender.setParameters(params);
        }
      }
    }
  }

  Future<void> restartIce() async {
    if (_peerConnection == null) return;
    _safeAdd(_iceStateController, VibeIceState.reconnecting);
    
    // In flutter_webrtc, we typically create a new offer with iceRestart: true
    if (_isCaller) {
      final offer = await _peerConnection!.createOffer({'iceRestart': true});
      await _peerConnection!.setLocalDescription(offer);
      await _db.collection('vibetalk_rooms').doc(_roomId).update({
        'offer': offer.toMap(),
        'reconnectionState': 'restarting',
      });
    }
  }

  Future<void> _handleIceFailure() async {
    // Basic auto-retry logic
    
    await restartIce();
  }

  Future<void> _createOffer() async {
    final pc = _peerConnection;
    if (pc == null || _roomId == null) return;
    
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    await _db.collection('vibetalk_rooms').doc(_roomId).update({'offer': offer.toMap()});

    _db.collection('vibetalk_rooms').doc(_roomId).snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data['answer'] != null) {
        final remoteDesc = await pc.getRemoteDescription();
        if (remoteDesc == null) {
          final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
          await pc.setRemoteDescription(answer);
          await _processQueuedCandidates();
        }
      }
    });
  }

  Future<void> _listenForOffer() async {
    _db.collection('vibetalk_rooms').doc(_roomId).snapshots().listen((snapshot) async {
      final pc = _peerConnection;
      if (pc == null) return;
      
      final data = snapshot.data();
      if (data != null && data['offer'] != null) {
        final remoteDesc = await pc.getRemoteDescription();
        if (remoteDesc == null) {
          final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
          await pc.setRemoteDescription(offer);
          await _processQueuedCandidates();
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          await _db.collection('vibetalk_rooms').doc(_roomId).update({'answer': answer.toMap()});
        }
      }
    });
  }

  void _listenForRemoteIceCandidates(bool isCaller) {
    final String collection = isCaller ? 'calleeCandidates' : 'callerCandidates';
    _db.collection('vibetalk_rooms').doc(_roomId).collection(collection).snapshots().listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && _peerConnection != null) {
            final candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
            final remoteDesc = await _peerConnection!.getRemoteDescription();
            if (remoteDesc != null) {
              await _peerConnection!.addCandidate(candidate);
            } else {
              _remoteCandidatesQueue.add(candidate);
            }
          }
        }
      }
    });
  }

  Future<void> _processQueuedCandidates() async {
    if (_peerConnection == null) return;
    for (final candidate in _remoteCandidatesQueue) {
      await _peerConnection!.addCandidate(candidate);
    }
    _remoteCandidatesQueue.clear();
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) => track.enabled = !isMuted);
  }

  Future<void> _deleteSubcollection(String path) async {
    try {
      final snap = await _db.collection(path).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _statsTimer?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    _iceStateController?.close();
    _audioLevelController?.close();
    _remoteAudioLevelController?.close();
    _qualityController?.close();

    // Deep cleanup signaling data to prevent storage leaks
    if (_roomId != null) {
      await _deleteSubcollection('vibetalk_rooms/$_roomId/callerCandidates');
      await _deleteSubcollection('vibetalk_rooms/$_roomId/calleeCandidates');
      try {
        await _db.collection('vibetalk_rooms').doc(_roomId).delete();
      } catch (_) {}
    }
    if (_uid != null) {
      try {
        await _db.collection('vibetalk_queue').doc(_uid).delete();
      } catch (_) {}
    }
  }
}

enum VibeQualityState { excellent, good, fair, poor }
