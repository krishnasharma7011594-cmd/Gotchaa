import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the horizontal PageView controller for the top-level shell.
final shellPageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController(initialPage: 1);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Tracks the active horizontal page index.
final shellPageIndexProvider = StateProvider<int>((ref) => 1);

/// Tracks the active tab index inside MainShell.
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);
