import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../security/e2ee_service.dart';

enum RTCConnectionState {
  initial,
  calling, // Outgoing
  ringing, // Incoming
  connecting,
  connected,
  disconnected,
  failed,
}

class RTCService extends ChangeNotifier {
  RTCService(this._e2eeService);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final E2EEService _e2eeService;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCConnectionState _state = RTCConnectionState.initial;
  RTCConnectionState get state => _state;

  String? _currentCallId;
  String? _myUid;
  String? _targetUid;
  SecretKey? _sharedSecret;
  bool _isVideo = false;

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Start a new call (Outgoing)
  Future<void> startCall({
    required String myUid,
    required String targetUid,
    required SecretKey sharedSecret,
    required bool isVideo,
    required String chatId,
  }) async {
    _myUid = myUid;
    _targetUid = targetUid;
    _sharedSecret = sharedSecret;
    _isVideo = isVideo;
    _state = RTCConnectionState.calling;
    notifyListeners();

    _currentCallId = '${chatId}_call_${DateTime.now().millisecondsSinceEpoch}';

    await _prepareLocalMedia();
    await _createPeerConnection();
    await _createOffer();

    // Create a call document in Firestore
    await _db.collection('calls').doc(_currentCallId).set({
      'chatId': chatId,
      'callerId': _myUid,
      'calleeId': _targetUid,
      'isVideo': isVideo,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _listenToCallStatus();
    _listenForAnswer();
    _listenForRemoteIceCandidates(true);
  }

  /// Join an existing call (Incoming)
  Future<void> joinCall({
    required String callId,
    required String myUid,
    required String targetUid,
    required SecretKey sharedSecret,
    required bool isVideo,
  }) async {
    _currentCallId = callId;
    _myUid = myUid;
    _targetUid = targetUid;
    _sharedSecret = sharedSecret;
    _isVideo = isVideo;
    _state = RTCConnectionState.connecting;
    notifyListeners();

    await _prepareLocalMedia();
    await _createPeerConnection();

    // Get the offer from Firestore
    final doc = await _db.collection('calls').doc(_currentCallId).get();
    final data = doc.data();
    if (data != null && data['offer'] != null) {
      final decryptedSDP =
          await _e2eeService.decrypt(data['offer'], _sharedSecret!);
      final offerMap = jsonDecode(decryptedSDP);

      await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(offerMap['sdp'], offerMap['type']));

      await _createAnswer();
      await _db
          .collection('calls')
          .doc(_currentCallId)
          .update({'status': 'connected'});

      _listenToCallStatus();
      _listenForRemoteIceCandidates(false);
    }
  }

  Future<void> _prepareLocalMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': _isVideo
          ? {
              'facingMode': 'user',
              'width': '1280',
              'height': '720',
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = _localStream;
    notifyListeners();
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
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
      ]
    });

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceCandidate = (candidate) async {
      if (_currentCallId != null && _sharedSecret != null) {
        final collection = (_myUid == _targetUid)
            ? 'dummy'
            : (_state == RTCConnectionState.calling
                ? 'callerCandidates'
                : 'calleeCandidates');
        // We use a more deterministic approach for collection naming
        final isCaller = _state == RTCConnectionState.calling;
        final targetCollection =
            isCaller ? 'callerCandidates' : 'calleeCandidates';

        final candidateData = jsonEncode(candidate.toMap());
        final encryptedCandidate =
            await _e2eeService.encrypt(candidateData, _sharedSecret!);

        await _db
            .collection('calls')
            .doc(_currentCallId)
            .collection(targetCollection)
            .add({'data': encryptedCandidate});
      }
    };

    _peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        _state = RTCConnectionState.connected;
        notifyListeners();
      }
    };

    _peerConnection?.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        hangUp();
      }
    };
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final encryptedSDP =
        await _e2eeService.encrypt(jsonEncode(offer.toMap()), _sharedSecret!);
    await _db
        .collection('calls')
        .doc(_currentCallId)
        .update({'offer': encryptedSDP});
  }

  Future<void> _createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    final encryptedSDP =
        await _e2eeService.encrypt(jsonEncode(answer.toMap()), _sharedSecret!);
    await _db
        .collection('calls')
        .doc(_currentCallId)
        .update({'answer': encryptedSDP});
  }

  void _listenForAnswer() {
    _db
        .collection('calls')
        .doc(_currentCallId)
        .snapshots()
        .listen((snapshot) async {
      final data = snapshot.data();
      if (data != null &&
          data['answer'] != null &&
          _state == RTCConnectionState.calling) {
        final remoteDesc = await _peerConnection!.getRemoteDescription();
        if (remoteDesc == null) {
          final decryptedSDP =
              await _e2eeService.decrypt(data['answer'], _sharedSecret!);
          final answerMap = jsonDecode(decryptedSDP);
          await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(answerMap['sdp'], answerMap['type']));
        }
      }
    });
  }

  void _listenToCallStatus() {
    _db.collection('calls').doc(_currentCallId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['status'] == 'ended') {
        hangUp(notifyDb: false);
      }
    });
  }

  void _listenForRemoteIceCandidates(bool isCaller) {
    final targetCollection = isCaller ? 'calleeCandidates' : 'callerCandidates';
    _db
        .collection('calls')
        .doc(_currentCallId)
        .collection(targetCollection)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          _processIceCandidate(data['data']);
        }
      }
    });
  }

  Future<void> _processIceCandidate(String encryptedData) async {
    if (_sharedSecret == null || _peerConnection == null) return;
    final decrypted = await _e2eeService.decrypt(encryptedData, _sharedSecret!);
    final map = jsonDecode(decrypted);
    await _peerConnection!.addCandidate(
        RTCIceCandidate(map['candidate'], map['sdpMid'], map['sdpMLineIndex']));
  }

  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        notifyListeners();
      }
    }
  }

  Future<void> toggleCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        notifyListeners();
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _isVideo) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    }
  }

  void hangUp({bool notifyDb = true}) async {
    if (notifyDb && _currentCallId != null) {
      await _db
          .collection('calls')
          .doc(_currentCallId)
          .update({'status': 'ended'});
    }

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _state = RTCConnectionState.initial;

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    notifyListeners();
  }

  @override
  void dispose() {
    hangUp();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
