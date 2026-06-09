import 'package:cloud_firestore/cloud_firestore.dart';

class CircleModel {
  CircleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.coverImageUrl,
    required this.hostId,
    required this.eventDate,
    required this.memberLimit,
    required this.locationName,
    required this.ageGroup,
    required this.language,
    required this.isPrivate,
    required this.isApprovalRequired,
    required this.memberIds,
    required this.isActive,
    required this.tags,
    required this.createdAt,
    this.locationLatLng,
    this.notifiedStart = false,
  });

  factory CircleModel.fromMap(Map<String, dynamic> map, String docId) =>
      CircleModel(
        id: docId,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        category: map['category'] ?? '',
        city: map['city'] ?? '',
        coverImageUrl: map['coverImageUrl'] ?? '',
        hostId: map['hostId'] ?? '',
        eventDate: (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        memberLimit: map['memberLimit'] ?? 0,
        locationName: map['locationName'] ?? '',
        locationLatLng: map['locationLatLng'] as GeoPoint?,
        ageGroup: map['ageGroup'] ?? 'Any',
        language: map['language'] ?? 'English',
        isPrivate: map['isPrivate'] ?? false,
        isApprovalRequired: map['isApprovalRequired'] ?? false,
        memberIds: List<String>.from(map['memberIds'] ?? []),
        isActive: map['isActive'] ?? true,
        tags: List<String>.from(map['tags'] ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        notifiedStart: map['notifiedStart'] ?? false,
      );
  final String id;
  final String title;
  final String description;
  final String category;
  final String city;
  final String coverImageUrl;
  final String hostId;
  final DateTime eventDate;
  final int memberLimit;
  final String locationName;
  final GeoPoint? locationLatLng; // private - only visible to confirmed members
  final String ageGroup;
  final String language;
  final bool isPrivate;
  final bool isApprovalRequired;
  final List<String> memberIds;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final bool notifiedStart;

  CircleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? city,
    String? coverImageUrl,
    String? hostId,
    DateTime? eventDate,
    int? memberLimit,
    String? locationName,
    GeoPoint? locationLatLng,
    String? ageGroup,
    String? language,
    bool? isPrivate,
    bool? isApprovalRequired,
    List<String>? memberIds,
    bool? isActive,
    List<String>? tags,
    DateTime? createdAt,
    bool? notifiedStart,
  }) =>
      CircleModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        city: city ?? this.city,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        hostId: hostId ?? this.hostId,
        eventDate: eventDate ?? this.eventDate,
        memberLimit: memberLimit ?? this.memberLimit,
        locationName: locationName ?? this.locationName,
        locationLatLng: locationLatLng ?? this.locationLatLng,
        ageGroup: ageGroup ?? this.ageGroup,
        language: language ?? this.language,
        isPrivate: isPrivate ?? this.isPrivate,
        isApprovalRequired: isApprovalRequired ?? this.isApprovalRequired,
        memberIds: memberIds ?? this.memberIds,
        isActive: isActive ?? this.isActive,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        notifiedStart: notifiedStart ?? this.notifiedStart,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'city': city,
        'coverImageUrl': coverImageUrl,
        'hostId': hostId,
        'eventDate': Timestamp.fromDate(eventDate),
        'memberLimit': memberLimit,
        'locationName': locationName,
        'locationLatLng': locationLatLng,
        'ageGroup': ageGroup,
        'language': language,
        'isPrivate': isPrivate,
        'isApprovalRequired': isApprovalRequired,
        'memberIds': memberIds,
        'isActive': isActive,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
        'notifiedStart': notifiedStart,
      };

  /// Utility to remove sensitive location coordinates for non-members
  CircleModel toPublicView(String currentUserId) {
    if (memberIds.contains(currentUserId) || hostId == currentUserId) {
      return this;
    }
    return copyWith(locationLatLng: null);
  }
}
