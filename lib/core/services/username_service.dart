import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Validates a username based on rules.
  /// Returns null if valid, or an error message if invalid.
  String? validateUsername(String username) {
    if (username.length < 3) {
      return 'Username must be at least 3 characters long.';
    }
    if (username.length > 20) {
      return 'Username cannot be more than 20 characters.';
    }
    
    // Only letters, numbers, and underscores allowed
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(username)) {
      return 'Only letters, numbers, and underscores are allowed.';
    }

    return null; // Valid
  }

  /// Checks if a username exists in the globally unique indexed system.
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  /// Generates a list of suggested usernames if the chosen one is taken.
  Future<List<String>> generateSuggestions(String baseName) async {
    final cleanBase = baseName.replaceAll(RegExp('[^a-zA-Z0-9_]'), '').toLowerCase();
    final shortBase = cleanBase.length > 15 ? cleanBase.substring(0, 15) : cleanBase;
    
    final suggestions = <String>{};
    
    while (suggestions.length < 5) {
      // Different suggestion strategies
      final int randGen = _random.nextInt(4);
      String potential = '';
      
      switch(randGen) {
        case 0:
          potential = '${shortBase}_${_random.nextInt(999)}';
          break;
        case 1:
          potential = '$shortBase${_random.nextInt(9999)}';
          break;
        case 2:
          potential = '${shortBase}_vibe';
          break;
        case 3:
          potential = 'user_$shortBase';
          break;
      }
      
      // Prevent duplicates in current suggestion list
      if (!suggestions.contains(potential)) {
        // Only add if it's actually available
        final bool available = await isUsernameAvailable(potential);
        if (available) {
          suggestions.add(potential);
        }
      }
    }
    return suggestions.toList();
  }

  /// Generates an anonymous username for chat (e.g. VibeTalk)
  String generateAnonymousUsername() {
    const adjectives = ['lonely', 'happy', 'cool', 'shadow', 'silent', 'mystic', 'neon'];
    const nouns = ['tiger', 'wolf', 'eagle', 'panda', 'fox', 'dragon', 'ninja'];
    
    final adj = adjectives[_random.nextInt(adjectives.length)];
    final noun = nouns[_random.nextInt(nouns.length)];
    final num = _random.nextInt(9999);
    
    return '${adj}_${noun}_$num';
  }

  /// Updates a username, with a 7-day restriction check, and reserves it in `usernames` collection.
  Future<bool> updateUsername({
    required String userId, 
    required String oldUsername, 
    required String newUsername
  }) async {
    final docRef = _firestore.collection('users').doc(userId);
    final userSnap = await docRef.get();
    
    if (!userSnap.exists) return false;
    final data = userSnap.data()!;
    
    // Check last update time
    if (data.containsKey('lastUsernameUpdate') && data['lastUsernameUpdate'] != null) {
      final lastUpdate = (data['lastUsernameUpdate'] as Timestamp).toDate();
      final difference = DateTime.now().difference(lastUpdate);
      if (difference.inDays < 7) {
        throw Exception('You can only change your username once every 7 days.');
      }
    }

    // Check availability one last time before setting
    final lowerNew = newUsername.toLowerCase();
    final isAvailable = await isUsernameAvailable(lowerNew);
    if (!isAvailable) {
      throw Exception('Username is already taken.');
    }

    await _firestore.runTransaction((tx) async {
      final newRef = _firestore.collection('usernames').doc(lowerNew);
      final existingNew = await tx.get(newRef);
      if (existingNew.exists && existingNew.data()?['uid'] != userId) {
        throw Exception('Username is already taken.');
      }
      
      // Release old username
      if (oldUsername.isNotEmpty) {
        tx.delete(_firestore.collection('usernames').doc(oldUsername.toLowerCase()));
      }

      // Reserve new username
      if (lowerNew.isNotEmpty) {
        tx.set(newRef, {'uid': userId});
      }

      // Update user document
      tx.update(docRef, {
        'username': lowerNew,
        'lastUsernameUpdate': FieldValue.serverTimestamp(),
      });
    });

    return true;
  }
}
