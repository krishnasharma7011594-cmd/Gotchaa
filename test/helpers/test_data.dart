import 'package:gotchaa/core/models/post_model.dart';
import 'package:gotchaa/core/models/user_profile.dart';
import 'package:gotchaa/features/services/domain/models/service_model.dart';
import 'package:gotchaa/core/models/chat_models.dart';
import 'package:flutter/material.dart';

/// Test User 1: English speaker India
final testUser1 = UserProfile(
  uid: 'user_in',
  username: 'testuser_in',
  displayName: 'India User',
  email: 'india@example.com',
  createdAt: DateTime.now(),
  nation: {'currentCountry': 'IN', 'currentContinent': 'Asia', 'languageCode': 'en'},
  hasPickedLanguage: true,
  ageVerified: true,
);

/// Test User 2: Spanish speaker Mexico
final testUser2 = UserProfile(
  uid: 'user_mx',
  username: 'testuser_mx',
  displayName: 'Mexico User',
  email: 'mexico@example.com',
  createdAt: DateTime.now(),
  nation: {'currentCountry': 'MX', 'currentContinent': 'North America', 'languageCode': 'es'},
  hasPickedLanguage: true,
  ageVerified: true,
);

/// Test User 3: Arabic speaker UAE
final testUser3 = UserProfile(
  uid: 'user_uae',
  username: 'testuser_uae',
  displayName: 'UAE User',
  email: 'uae@example.com',
  createdAt: DateTime.now(),
  nation: {'currentCountry': 'AE', 'currentContinent': 'Asia', 'languageCode': 'ar'},
  hasPickedLanguage: true,
  ageVerified: true,
);

/// Test Posts
final testPost1 = PostModel(postId: 'post_1', uid: 'user_in', createdAt: DateTime.now(), caption: 'Post 1 from India', likesCount: 10, commentsCount: 5);
final testPost2 = PostModel(postId: 'post_2', uid: 'user_mx', createdAt: DateTime.now(), caption: 'Post 2 from Mexico', likesCount: 20, commentsCount: 10);
final testPost3 = PostModel(postId: 'post_3', uid: 'user_uae', createdAt: DateTime.now(), caption: 'Post 3 from UAE', likesCount: 30, commentsCount: 15);

/// Test Chat Messages (10 realistic messages)
final testChatMessageList = [
  MessageModel(id: '1', senderId: 'user_in', receiverId: 'user_mx', text: 'Hello from India!', timestamp: DateTime.now()),
  MessageModel(id: '2', senderId: 'user_mx', receiverId: 'user_in', text: 'Hola! How are you?', timestamp: DateTime.now()),
  MessageModel(id: '3', senderId: 'user_in', receiverId: 'user_mx', text: 'I am good, thanks!', timestamp: DateTime.now()),
  MessageModel(id: '4', senderId: 'user_mx', receiverId: 'user_in', text: 'Great to hear.', timestamp: DateTime.now()),
  MessageModel(id: '5', senderId: 'user_in', receiverId: 'user_uae', text: 'Hello UAE!', timestamp: DateTime.now()),
  MessageModel(id: '6', senderId: 'user_uae', receiverId: 'user_in', text: 'Hello! Welcome.', timestamp: DateTime.now()),
  MessageModel(id: '7', senderId: 'user_mx', receiverId: 'user_uae', text: 'Hola UAE!', timestamp: DateTime.now()),
  MessageModel(id: '8', senderId: 'user_uae', receiverId: 'user_mx', text: 'Hola Mexico!', timestamp: DateTime.now()),
  MessageModel(id: '9', senderId: 'user_in', receiverId: 'user_mx', text: 'Let's chat more.', timestamp: DateTime.now()),
  MessageModel(id: '10', senderId: 'user_mx', receiverId: 'user_in', text: 'Sure!', timestamp: DateTime.now()),
];

/// Test Services (21 services matching requested count)
final testServices = [
  const GotchaaService(id: 'swiggy', name: 'Swiggy', url: 'https://swiggy.com', category: ServiceCategory.food, brandColor: Colors.orange, description: 'Food delivery'),
  const GotchaaService(id: 'blinkit', name: 'Blinkit', url: 'https://blinkit.com', category: ServiceCategory.grocery, brandColor: Colors.yellow, description: 'Grocery delivery'),
  const GotchaaService(id: 'amazon', name: 'Amazon', url: 'https://amazon.com', category: ServiceCategory.shopping, brandColor: Colors.black, description: 'Shopping'),
  const GotchaaService(id: 'myntra', name: 'Myntra', url: 'https://myntra.com', category: ServiceCategory.fashion, brandColor: Colors.pink, description: 'Fashion'),
  const GotchaaService(id: 'booking', name: 'Booking.com', url: 'https://booking.com', category: ServiceCategory.hotels, brandColor: Colors.blue, description: 'Hotels'),
  const GotchaaService(id: 'makemytrip', name: 'MakeMyTrip', url: 'https://makemytrip.com', category: ServiceCategory.travel, brandColor: Colors.red, description: 'Travel'),
  const GotchaaService(id: 'bookmyshow', name: 'BookMyShow', url: 'https://bookmyshow.com', category: ServiceCategory.entertainment, brandColor: Colors.red, description: 'Movies'),
  const GotchaaService(id: '1mg', name: '1mg', url: 'https://1mg.com', category: ServiceCategory.health, brandColor: Colors.orange, description: 'Pharmacy'),
  const GotchaaService(id: 'urbancompany', name: 'Urban Company', url: 'https://urbancompany.com', category: ServiceCategory.home, brandColor: Colors.black, description: 'Home services'),
  const GotchaaService(id: 'uber', name: 'Uber', url: 'https://uber.com', category: ServiceCategory.transport, brandColor: Colors.black, description: 'Rides'),
  // Dummy services to reach 21
  const GotchaaService(id: 'service_11', name: 'Zomato', url: '', category: ServiceCategory.food, brandColor: Colors.red, description: 'Food'),
  const GotchaaService(id: 'service_12', name: 'Flipkart', url: '', category: ServiceCategory.shopping, brandColor: Colors.blue, description: 'Shopping'),
  const GotchaaService(id: 'service_13', name: 'Ola', url: '', category: ServiceCategory.transport, brandColor: Colors.green, description: 'Rides'),
  const GotchaaService(id: 'service_14', name: 'Netflix', url: '', category: ServiceCategory.entertainment, brandColor: Colors.red, description: 'Streaming'),
  const GotchaaService(id: 'service_15', name: 'Spotify', url: '', category: ServiceCategory.entertainment, brandColor: Colors.green, description: 'Music'),
  const GotchaaService(id: 'service_16', name: 'Airbnb', url: '', category: ServiceCategory.hotels, brandColor: Colors.pink, description: 'Stays'),
  const GotchaaService(id: 'service_17', name: 'Skyscanner', url: '', category: ServiceCategory.travel, brandColor: Colors.blue, description: 'Flights'),
  const GotchaaService(id: 'service_18', name: 'PharmEasy', url: '', category: ServiceCategory.health, brandColor: Colors.teal, description: 'Medicine'),
  const GotchaaService(id: 'service_19', name: 'Cult.fit', url: '', category: ServiceCategory.health, brandColor: Colors.black, description: 'Fitness'),
  const GotchaaService(id: 'service_20', name: 'Dunzo', url: '', category: ServiceCategory.grocery, brandColor: Colors.green, description: 'Delivery'),
  const GotchaaService(id: 'service_21', name: 'Nykaa', url: '', category: ServiceCategory.fashion, brandColor: Colors.pink, description: 'Beauty'),
];

/// Test Karma Transactions
final testKarmaTransactionList = [
  {'id': 'tx_1', 'amount': 10, 'type': 'earn', 'reason': 'Post created'},
  {'id': 'tx_2', 'amount': 5, 'type': 'spend', 'reason': 'Tip sent'},
  {'id': 'tx_3', 'amount': 20, 'type': 'earn', 'reason': 'Daily streak'},
];

// Helper functions for tests
PostModel getMockPost({String? postId, String? uid, String? caption, int? likesCount, int? commentsCount}) {
  return PostModel(
    postId: postId ?? 'post_mock',
    uid: uid ?? 'user_in',
    createdAt: DateTime.now(),
    caption: caption ?? 'Mock post caption',
    likesCount: likesCount ?? 0,
    commentsCount: commentsCount ?? 0,
  );
}

GotchaaService getMockService({required String id, required String name, String url = '', ServiceCategory category = ServiceCategory.food, Color brandColor = Colors.blue, String description = ''}) {
  return GotchaaService(
    id: id,
    name: name,
    url: url,
    category: category,
    brandColor: brandColor,
    description: description,
  );
}
