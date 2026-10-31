// Browser-only review entrypoint. Renders the real app/routes with clearly
// labelled sample data; never used by lib/main.dart or Android builds.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/storage/local_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/student_profile.dart';
import 'features/content/data/content_source.dart';

const reviewProfile = StudentProfile(
  uid: 'ui-review-student',
  fullName: 'Muhammad Haris',
  mobile: '+923001234567',
  gender: 'male',
  city: 'Pattoki',
  professionalYear: 2,
  institutionName: 'Quaid-e-Azam College of Pharmacy',
  affiliationStatus: AffiliationStatus.nonAffiliated,
  email: 'student@example.com',
  rollNumber: 'DP-2420',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Boxes.init();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => Stream.value(_ReviewUser())),
        authRepositoryProvider.overrideWithValue(_ReviewAuth()),
        profileProvider.overrideWith((ref) {
          final cached = ref
              .read(pendingProfileStoreProvider)
              .cached(reviewProfile.uid);
          return Stream.value(
            cached == null
                ? reviewProfile
                : StudentProfile.fromMap(reviewProfile.uid, cached),
          );
        }),
        contentProvider.overrideWith(
          (ref, key) => Stream.value(
            ContentSnapshot(
              value: key == 'pw_settings' ? <String, dynamic>{} : [],
              fromCache: false,
            ),
          ),
        ),
      ],
      child: const _ReviewApp(),
    ),
  );
}

class _ReviewApp extends StatelessWidget {
  const _ReviewApp();
  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.ltr,
    child: Banner(
      message: 'SAMPLE DATA',
      location: BannerLocation.bottomEnd,
      color: Color(0xFF38383D),
      child: HyzenApp(),
    ),
  );
}

// Only fixture adapters live here. No review credentials or cloud writes.
class _ReviewUser implements User {
  @override
  String get uid => reviewProfile.uid;
  @override
  String? get displayName => reviewProfile.fullName;
  @override
  String? get email => reviewProfile.email;
  @override
  String? get photoURL => null;
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewAuth implements AuthRepository {
  @override
  Future<void> sendReset(String email) async => throw UnsupportedError(
    'Use the normal app preview with your own account for authentication actions.',
  );
  @override
  Future<void> signOut() async => throw UnsupportedError(
    'This UI review uses sample data; there is no authenticated session.',
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
