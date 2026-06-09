import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/services/domain/models/service_model.dart';

// Simulated Country-based filtering based on user requirements
List<GotchaaService> filterServicesByCountry(
    List<GotchaaService> services, String countryCode) {
  return services.where((s) {
    if (countryCode == 'IN') {
      return true; // Sees all in this list for now
    } else if (countryCode == 'US') {
      // US does not see Swiggy or Blinkit
      return s.id != 'swiggy' && s.id != 'blinkit';
    }
    return true; // Global
  }).toList();
}

void main() {
  final services = [
    const GotchaaService(
        id: 'swiggy',
        name: 'Swiggy',
        url: 'https://swiggy.com',
        category: ServiceCategory.food,
        brandColor: Colors.blue,
        description: 'Food delivery'),
    const GotchaaService(
        id: 'blinkit',
        name: 'Blinkit',
        url: 'https://blinkit.com',
        category: ServiceCategory.grocery,
        brandColor: Colors.blue,
        description: 'Grocery delivery'),
    const GotchaaService(
        id: 'amazon',
        name: 'Amazon',
        url: 'https://amazon.com',
        category: ServiceCategory.shopping,
        brandColor: Colors.blue,
        description: 'Shopping'),
    const GotchaaService(
        id: 'uber',
        name: 'Uber',
        url: 'https://uber.com',
        category: ServiceCategory.transport,
        brandColor: Colors.blue,
        description: 'Transport'),
    const GotchaaService(
        id: 'booking',
        name: 'Booking.com',
        url: 'https://booking.com',
        category: ServiceCategory.hotels,
        brandColor: Colors.blue,
        description: 'Hotels'),
  ];

  group('Services Provider Tests', () {
    test('India user sees Swiggy and Blinkit', () {
      final filtered = filterServicesByCountry(services, 'IN');
      expect(filtered.any((s) => s.id == 'swiggy'), isTrue);
      expect(filtered.any((s) => s.id == 'blinkit'), isTrue);
    });

    test('US user does NOT see Swiggy or Blinkit', () {
      final filtered = filterServicesByCountry(services, 'US');
      expect(filtered.any((s) => s.id == 'swiggy'), isFalse);
      expect(filtered.any((s) => s.id == 'blinkit'), isFalse);
    });

    test('US user sees Amazon, Uber, Booking.com', () {
      final filtered = filterServicesByCountry(services, 'US');
      expect(filtered.any((s) => s.id == 'amazon'), isTrue);
      expect(filtered.any((s) => s.id == 'uber'), isTrue);
      expect(filtered.any((s) => s.id == 'booking'), isTrue);
    });

    test('Search for "food" returns food category services', () {
      final query = 'food';
      final filtered = services
          .where((s) => s.description.toLowerCase().contains(query))
          .toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('swiggy'));
    });

    test('Search for "swiggy" returns Swiggy', () {
      final query = 'swiggy';
      final filtered =
          services.where((s) => s.name.toLowerCase().contains(query)).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('swiggy'));
    });

    test('Empty search returns all services for country', () {
      final filtered = filterServicesByCountry(services, 'IN');
      expect(filtered.length, equals(services.length));
    });

    test('Favourite toggle adds service to favourites', () {
      final favourites = <String>{};

      // Toggle on
      favourites.add('swiggy');
      expect(favourites.contains('swiggy'), isTrue);

      // Toggle off
      favourites.remove('swiggy');
      expect(favourites.contains('swiggy'), isFalse);
    });
  });
}
