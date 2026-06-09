import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../domain/models/service_model.dart';

final servicesProvider = Provider<List<GotchaaService>>((ref) => [
    const GotchaaService(
      id: 'swiggy',
      name: 'Swiggy',
      url: 'https://www.swiggy.com',
      category: ServiceCategory.food,
      brandColor: Color(0xFFFC8019),
      description: 'Order food delivery online',
      iconAsset: 'https://logo.clearbit.com/swiggy.com',
    ),
    const GotchaaService(
      id: 'blinkit',
      name: 'Blinkit',
      url: 'https://blinkit.com',
      category: ServiceCategory.grocery,
      brandColor: Color(0xFFFCCC04),
      description: 'Groceries delivered in minutes',
      iconAsset: 'https://logo.clearbit.com/blinkit.com',
    ),
    const GotchaaService(
      id: 'amazon',
      name: 'Amazon',
      url: 'https://www.amazon.in',
      category: ServiceCategory.shopping,
      brandColor: Color(0xFFFF9900),
      description: 'Shop electronics, apparel, books',
      iconAsset: 'https://logo.clearbit.com/amazon.in',
    ),
    const GotchaaService(
      id: 'myntra',
      name: 'Myntra',
      url: 'https://www.myntra.com',
      category: ServiceCategory.fashion,
      brandColor: Color(0xFFF13AB1),
      description: 'Online fashion shopping',
      iconAsset: 'https://logo.clearbit.com/myntra.com',
    ),
    const GotchaaService(
      id: 'booking',
      name: 'Booking.com',
      url: 'https://www.booking.com',
      category: ServiceCategory.hotels,
      brandColor: Color(0xFF003580),
      description: 'Find hotels and homes',
      iconAsset: 'https://logo.clearbit.com/booking.com',
    ),
    const GotchaaService(
      id: 'makemytrip',
      name: 'MakeMyTrip',
      url: 'https://www.makemytrip.com',
      category: ServiceCategory.travel,
      brandColor: Color(0xFFD52A20),
      description: 'Flight and train bookings',
      iconAsset: 'https://logo.clearbit.com/makemytrip.com',
    ),
    const GotchaaService(
      id: 'bookmyshow',
      name: 'BookMyShow',
      url: 'https://in.bookmyshow.com',
      category: ServiceCategory.entertainment,
      brandColor: Color(0xFFC22F3E),
      description: 'Movie tickets, plays, events',
      iconAsset: 'https://logo.clearbit.com/bookmyshow.com',
    ),
    const GotchaaService(
      id: '1mg',
      name: '1mg',
      url: 'https://www.1mg.com',
      category: ServiceCategory.health,
      brandColor: Color(0xFFF85D51),
      description: 'Online pharmacy and healthcare',
      iconAsset: 'https://logo.clearbit.com/1mg.com',
    ),
    const GotchaaService(
      id: 'urbancompany',
      name: 'Urban Company',
      url: 'https://www.urbancompany.com',
      category: ServiceCategory.home,
      brandColor: Color(0xFF1E2833),
      description: 'Home services and repairs',
      iconAsset: 'https://logo.clearbit.com/urbancompany.com',
    ),
    const GotchaaService(
      id: 'uber',
      name: 'Uber',
      url: 'https://m.uber.com',
      category: ServiceCategory.transport,
      brandColor: Color(0xFF000000),
      description: 'Book rides instantly',
      iconAsset: 'https://logo.clearbit.com/uber.com',
    ),
    const GotchaaService(
      id: 'rapido',
      name: 'Rapido',
      url: 'https://www.rapido.bike',
      category: ServiceCategory.transport,
      brandColor: Color(0xFFF9D915),
      description: 'Bike taxis and auto rides',
      iconAsset: 'https://logo.clearbit.com/rapido.bike',
    ),
    const GotchaaService(
      id: 'eatsure',
      name: 'EatSure',
      url: 'https://www.eatsure.com',
      category: ServiceCategory.food,
      brandColor: Color(0xFFE84B3A),
      description: 'Cloud kitchen brands in one place',
      iconAsset: 'https://eatsure.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'fassos',
      name: 'Fassos',
      url: 'https://www.fassos.com',
      category: ServiceCategory.food,
      brandColor: Color(0xFFE63946),
      description: 'Quick wraps and meals',
      iconAsset: 'https://fassos.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'zepto',
      name: 'Zepto',
      url: 'https://www.zepto.com',
      category: ServiceCategory.grocery,
      brandColor: Color(0xFF8B2FC9),
      description: '10 minute grocery delivery',
      iconAsset: 'https://zepto.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'flipkart',
      name: 'Flipkart',
      url: 'https://www.flipkart.com',
      category: ServiceCategory.shopping,
      brandColor: Color(0xFFF7971E),
      description: "India's favourite online store",
      iconAsset: 'https://flipkart.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'ajio',
      name: 'Ajio',
      url: 'https://www.ajio.com',
      category: ServiceCategory.fashion,
      brandColor: Color(0xFF1B1B2F),
      description: 'Trendy fashion by Reliance',
      iconAsset: 'https://ajio.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'nykaa',
      name: 'Nykaa',
      url: 'https://www.nykaa.com',
      category: ServiceCategory.fashion,
      brandColor: Color(0xFFFC2779),
      description: 'Beauty and fashion for everyone',
      iconAsset: 'https://nykaa.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'oyo',
      name: 'OYO',
      url: 'https://www.oyorooms.com',
      category: ServiceCategory.hotels,
      brandColor: Color(0xFFEE2E24),
      description: 'Affordable hotels everywhere',
      iconAsset: 'https://oyorooms.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'airbnb',
      name: 'Airbnb',
      url: 'https://www.airbnb.com',
      category: ServiceCategory.hotels,
      brandColor: Color(0xFFFF5A5F),
      description: 'Unique stays worldwide',
      iconAsset: 'https://airbnb.com/favicon.ico',
    ),
    const GotchaaService(
      id: 'district',
      name: 'District',
      url: 'https://www.district.in',
      category: ServiceCategory.entertainment,
      brandColor: Color(0xFFE8334A),
      description: 'Events and experiences by Zomato',
      iconAsset: 'https://district.in/favicon.ico',
    ),
    const GotchaaService(
      id: 'practo',
      name: 'Practo',
      url: 'https://www.practo.com',
      category: ServiceCategory.health,
      brandColor: Color(0xFF2ECC71),
      description: 'Book doctors and consultations',
      iconAsset: 'https://practo.com/favicon.ico',
    ),
  ]);

final recentServicesProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  
  final db = FirebaseFirestore.instance;
  return db
      .collection('users_private')
      .doc(uid)
      .collection('recentServices')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

final favouriteServicesProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  
  final db = FirebaseFirestore.instance;
  return db
      .collection('users_private')
      .doc(uid)
      .collection('favouriteServices')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

final servicesSearchQueryProvider = StateProvider<String>((ref) => '');
final servicesSelectedCategoryProvider = StateProvider<ServiceCategory>((ref) => ServiceCategory.all);

final filteredServicesProvider = Provider<List<GotchaaService>>((ref) {
  final services = ref.watch(servicesProvider);
  final query = ref.watch(servicesSearchQueryProvider).toLowerCase();
  final category = ref.watch(servicesSelectedCategoryProvider);

  return services.where((service) {
    final matchesCategory = category == ServiceCategory.all || service.category == category;
    final matchesQuery = service.name.toLowerCase().contains(query) || 
                         service.description.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});
