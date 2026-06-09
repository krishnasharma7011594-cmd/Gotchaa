import 'package:flutter/material.dart';

enum ServiceCategory {
  all,
  food,
  grocery,
  shopping,
  fashion,
  hotels,
  travel,
  entertainment,
  health,
  home,
  transport,
  other,
}

class GotchaaService {

  const GotchaaService({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.brandColor,
    required this.description,
    this.iconAsset = '',
  });

  factory GotchaaService.fromMap(Map<String, dynamic> map) => GotchaaService(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ServiceCategory.all,
      ),
      brandColor: Color(map['brandColor'] ?? 0xFF1A56C4),
      description: map['description'] ?? '',
      iconAsset: map['iconAsset'] ?? '',
    );
  final String id;
  final String name;
  final String url;
  final ServiceCategory category;
  final Color brandColor;
  final String description;
  final String iconAsset;

  Map<String, dynamic> toMap() => {
      'id': id,
      'name': name,
      'url': url,
      'category': category.name,
      'brandColor': brandColor.value,
      'description': description,
      'iconAsset': iconAsset,
    };
}
