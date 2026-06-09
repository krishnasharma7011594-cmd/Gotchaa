import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../models/circle_message.dart';
import '../models/circle_model.dart';

class CirclesLocalCacheService {
  CirclesLocalCacheService._internal();
  static final CirclesLocalCacheService instance = CirclesLocalCacheService._internal();

  Future<File> _getFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  // Cache circles feed
  Future<void> cacheCircles(List<CircleModel> circles) async {
    try {
      final file = await _getFile('cached_circles.json');
      final list = circles.map((c) => c.toMap()).toList();
      // Handle Timestamp conversion for serialization
      for (final map in list) {
        if (map['eventDate'] != null) {
          map['eventDate'] = (map['eventDate'] as dynamic).millisecondsSinceEpoch;
        }
        if (map['createdAt'] != null) {
          map['createdAt'] = (map['createdAt'] as dynamic).millisecondsSinceEpoch;
        }
        // Exclude locationLatLng to preserve privacy in public cache
        map.remove('locationLatLng');
      }
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      // Silently fail
    }
  }

  // Load cached circles
  Future<List<CircleModel>> getCachedCircles() async {
    try {
      final file = await _getFile('cached_circles.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Reconstruct timestamp objects
        if (map['eventDate'] != null) {
          map['eventDate'] = Timestamp.fromMillisecondsSinceEpoch(map['eventDate'] as int);
        }
        if (map['createdAt'] != null) {
          map['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(map['createdAt'] as int);
        }
        return CircleModel.fromMap(map, map['id'] ?? '');
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache group chat messages
  Future<void> cacheMessages(String circleId, List<CircleMessage> messages) async {
    try {
      final file = await _getFile('cached_msgs_$circleId.json');
      final list = messages.map((m) => m.toMap()).toList();
      for (final map in list) {
        if (map['timestamp'] != null) {
          map['timestamp'] = (map['timestamp'] as dynamic).millisecondsSinceEpoch;
        }
        if (map['ttl'] != null) {
          map['ttl'] = (map['ttl'] as dynamic).millisecondsSinceEpoch;
        }
      }
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      // Silently fail
    }
  }

  // Load cached messages
  Future<List<CircleMessage>> getCachedMessages(String circleId) async {
    try {
      final file = await _getFile('cached_msgs_$circleId.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item);
        if (map['timestamp'] != null) {
          map['timestamp'] = Timestamp.fromMillisecondsSinceEpoch(map['timestamp'] as int);
        }
        if (map['ttl'] != null) {
          map['ttl'] = Timestamp.fromMillisecondsSinceEpoch(map['ttl'] as int);
        }
        return CircleMessage.fromMap(map, map['messageId'] ?? '');
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
