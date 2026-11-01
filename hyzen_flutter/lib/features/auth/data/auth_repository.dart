import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../domain/student_profile.dart';

/// Firebase Auth (same project) — credentials owned by Firebase only.
class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User> signIn(String email, String password) async {
    try {
      final c = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return c.user!;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('signIn error: ${e.code} ${e.message}');
      throw FriendlyException(AuthErrorMapper.message(e.code), code: e.code);
    } catch (e) {
      if (kDebugMode) debugPrint('signIn unknown: $e');
      throw FriendlyException(
        'Sign-in failed. Please check your connection and try again.',
      );
    }
  }

  Future<User> createAccount(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final c = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        try {
          await c.user!.updateDisplayName(displayName);
        } catch (_) {}
      }
      return c.user!;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('create error: ${e.code}');
      throw FriendlyException(AuthErrorMapper.message(e.code), code: e.code);
    }
  }

  Future<void> sendReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether an account exists for 'user-not-found'.
      if (e.code == 'user-not-found') return;
      throw FriendlyException(AuthErrorMapper.message(e.code), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();
}

/// NEW BACKEND EXTENSION: students/{uid}. Proposed rules: firestore.rules.proposed
class StudentProfileRepository {
  StudentProfileRepository(this._db);
  final FirebaseFirestore _db;
  static const collection = 'students';

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(collection).doc(uid);

  Future<StudentProfile?> fetch(String uid) async {
    final s = await _doc(uid).get();
    if (!s.exists || s.data() == null) return null;
    return StudentProfile.fromMap(uid, s.data()!);
  }

  Stream<StudentProfile?> watch(String uid) => _doc(uid).snapshots().map(
    (s) => (!s.exists || s.data() == null)
        ? null
        : StudentProfile.fromMap(uid, s.data()!),
  );

  /// Idempotent recovery: retain immutable identity and createdAt on retries.
  Future<void> create(StudentProfile p) async {
    await _db
        .runTransaction((tx) async {
          final doc = _doc(p.uid);
          final snapshot = await tx.get(doc);
          if (snapshot.exists) {
            final value = p.toWriteMap()
              ..remove('uid')
              ..remove('email')
              ..remove('role');
            tx.update(doc, {
              ...value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            tx.set(doc, {
              ...p.toWriteMap(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        })
        .timeout(const Duration(seconds: 20));
  }

  /// Students may update only permitted fields (uid/email/role/createdAt are immutable).
  Future<void> update(StudentProfile p) async {
    final m = p.toWriteMap()
      ..remove('uid')
      ..remove('email')
      ..remove('role');
    await _doc(p.uid).update({...m, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
