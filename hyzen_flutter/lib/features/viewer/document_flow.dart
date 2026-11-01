import 'package:flutter_riverpod/flutter_riverpod.dart';

// Start suppressed until the native launch-intent queue has been checked.
final documentHandoffProvider = StateProvider<bool>((ref) => true);
final documentDraftRevisionProvider = StateProvider<int>((ref) => 0);
