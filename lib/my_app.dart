import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';

/// Simple wrapper for tests that need a MyApp widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap GotchaaApp with ProviderScope to provide the necessary providers.
    return const ProviderScope(child: GotchaaApp());
  }
}
