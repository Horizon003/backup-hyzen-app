import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/firebase_options.dart';
import '../core/storage/local_store.dart';
import 'app.dart';
import 'providers.dart';

/// Initialise only what the first frame needs. No artificial delay.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init failed: $e');
  }
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    Boxes.init(),
  ]);
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(results[0] as SharedPreferences),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const HyzenApp(),
    ),
  );
}
