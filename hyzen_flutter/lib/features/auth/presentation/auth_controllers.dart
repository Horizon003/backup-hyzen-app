import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../data/auth_repository.dart';
import '../domain/registration_draft.dart';
import '../domain/student_profile.dart';

class RegistrationController extends Notifier<RegistrationDraft> {
  @override
  RegistrationDraft build() => const RegistrationDraft();
  void update(RegistrationDraft Function(RegistrationDraft d) f) =>
      state = f(state);
  void reset() => state = const RegistrationDraft();
}

final registrationProvider =
    NotifierProvider<RegistrationController, RegistrationDraft>(
      RegistrationController.new,
    );

/// Profile created in the last successful signup (for the Success screen).
final lastCreatedProfileProvider = StateProvider<StudentProfile?>((_) => null);

/// True while createAccount + profile write run, so the router does not jump to
/// /home the instant Firebase reports the new session (Success screen comes first).
bool registrationInFlight = false;

class SubmitResult {
  const SubmitResult({required this.profile, required this.profileSynced});
  final StudentProfile profile;
  final bool profileSynced;
}

/// Account creation with clean partial-failure recovery:
/// 1. Firebase Auth user created (or, if email exists for the SAME just-created session, reused)
/// 2. students/{uid} written. If this fails, profile (no password) is stored locally
///    and retried automatically by profileProvider — the user is NOT stuck.
Future<SubmitResult> submitRegistration(Ref ref, String password) async {
  final draft = ref.read(registrationProvider);
  final errs = {
    ...draft.validatePersonal(),
    ...draft.validateAcademic(),
    ...draft.validateCredentials(password, password),
  };
  if (errs.isNotEmpty) throw FriendlyException(errs.values.first);
  if (!ref.read(firebaseReadyProvider)) {
    throw FriendlyException(
      'Can\u2019t reach PHARM D WITH HYZEN right now. Please check your connection.',
    );
  }

  final auth = ref.read(authRepositoryProvider);
  registrationInFlight = true;
  try {
    return await _create(ref, auth, draft, password);
  } finally {
    registrationInFlight = false;
  }
}

Future<SubmitResult> _create(
  Ref ref,
  AuthRepository auth,
  RegistrationDraft draft,
  String password,
) async {
  final user = await auth.createAccount(
    draft.email,
    password,
    displayName: draft.fullName.trim(),
  );
  final profile = draft.toProfile(user.uid);
  final pending = ref.read(pendingProfileStoreProvider);
  // Persist locally FIRST so a crash between steps never loses data.
  await pending.save(user.uid, profile.toWriteMap());
  final repository = ref.read(profileRepositoryProvider);
  unawaited(() async {
    try {
      final draft = profile.toWriteMap();
      await repository.create(profile);
      if (jsonEncode(pending.read(user.uid)) == jsonEncode(draft)) {
        await pending.clear(user.uid);
      }
    } catch (_) {
      /* Durable draft is retried by the profile stream. */
    }
  }());
  ref.invalidate(profileProvider);
  ref.read(lastCreatedProfileProvider.notifier).state = profile;
  return SubmitResult(profile: profile, profileSynced: false);
}

final submitRegistrationProvider = Provider(
  (ref) =>
      (String pw) => submitRegistration(ref, pw),
);
