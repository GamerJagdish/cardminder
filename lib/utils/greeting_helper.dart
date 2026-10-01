import 'dart:math';
import 'package:flutter/foundation.dart';

/// Helper utility providing dynamic greeting phrases on the home screen.
///
/// Employs a shuffle-bag algorithm ensuring:
/// 1. All greetings are shown in a randomized order before repeating any.
/// 2. Consecutive repeats across shuffle bag reshuffles are strictly avoided.
class GreetingHelper {
  static const List<String> greetings = [
    'Hi,',
    'Hello there,',
    'Hey owo,',
    'Welcome back,',
    'Howdy,',
    'What\'s up,',
    'Wassup gng,',
    'Sup cuh,',
    'Sup,',
  ];

  static List<String> _bag = [];
  static String? _lastGreeting;

  /// Returns the next randomized greeting without immediate repeats.
  static String nextGreeting({Random? random}) {
    if (_bag.isEmpty) {
      final rng = random ?? Random();
      final fresh = List<String>.from(greetings)..shuffle(rng);
      // If the next greeting to pop (the last item) is the same as the last served greeting,
      // swap it with the first item so there's never an immediate repeat.
      if (_lastGreeting != null &&
          fresh.length > 1 &&
          fresh.last == _lastGreeting) {
        final temp = fresh.last;
        fresh[fresh.length - 1] = fresh.first;
        fresh[0] = temp;
      }
      _bag = fresh;
    }
    final next = _bag.removeLast();
    _lastGreeting = next;
    return next;
  }

  /// Resets the shuffle bag state (useful for testing).
  @visibleForTesting
  static void reset() {
    _bag = [];
    _lastGreeting = null;
  }
}
