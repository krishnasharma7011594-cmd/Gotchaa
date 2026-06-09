import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotchaa/features/services/providers/services_provider.dart';
import 'package:gotchaa/features/services/domain/models/service_model.dart';

void main() {
  group('ServicesProvider Tests', () {
    test('Test filteredServicesProvider default state returns all services',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final services = container.read(filteredServicesProvider);
      final allServices = container.read(servicesProvider);

      expect(services.length, equals(allServices.length));
    });

    test('Test filteredServicesProvider filters by category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set category to food
      container.read(servicesSelectedCategoryProvider.notifier).state =
          ServiceCategory.food;

      final services = container.read(filteredServicesProvider);

      expect(services, isNotEmpty);
      expect(services.every((s) => s.category == ServiceCategory.food), isTrue);
    });

    test('Test filteredServicesProvider filters by search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set query to 'Swiggy'
      container.read(servicesSearchQueryProvider.notifier).state = 'Swiggy';

      final services = container.read(filteredServicesProvider);

      expect(services.length, equals(1));
      expect(services.first.name, equals('Swiggy'));
    });

    test('Test filteredServicesProvider filters by query case insensitively',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set query to 'swiggy' (lowercase)
      container.read(servicesSearchQueryProvider.notifier).state = 'swiggy';

      final services = container.read(filteredServicesProvider);

      expect(services.length, equals(1));
      expect(services.first.name, equals('Swiggy'));
    });

    test('Test search filters both name and description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set query to 'food' which appears in description of Swiggy and EatSure
      container.read(servicesSearchQueryProvider.notifier).state = 'food';

      final services = container.read(filteredServicesProvider);

      expect(services.length, greaterThanOrEqualTo(1));
      expect(services.any((s) => s.name == 'Swiggy'), isTrue);
    });
  });
}
