import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/auth/domain/registration_draft.dart';
import 'package:hyzen_pharmd/features/auth/domain/student_profile.dart';

void main() {
  test('empty draft fails each step', () {
    const d = RegistrationDraft();
    expect(d.validatePersonal(), isNotEmpty);
    expect(d.validateAcademic(), isNotEmpty);
  });

  test(
    'valid draft -> profile, roll number optional, role student, no password',
    () {
      const d = RegistrationDraft(
        fullName: 'Ali Raza',
        mobile: '03001234567',
        gender: 'male',
        city: 'Lahore',
        professionalYear: 2,
        institutionName: 'Punjab University College of Pharmacy',
        affiliation: AffiliationStatus.affiliated,
        universityId: 'pu',
        email: 'ali@example.com',
        acceptedTerms: true,
      );
      expect(d.validatePersonal(), isEmpty);
      expect(d.validateAcademic(), isEmpty);
      expect(d.validateCredentials('abcd1234', 'abcd1234'), isEmpty);
      final m = d.toProfile('UID1').toWriteMap();
      expect(m['uid'], 'UID1');
      expect(m['mobile'], '+923001234567');
      expect(m['role'], 'student');
      expect(m['rollNumber'], isNull);
      expect(m['affiliationStatus'], 'affiliated');
      expect((m['affiliatedUniversity'] as Map)['id'], 'pu');
      expect(m.keys.any((k) => k.toLowerCase().contains('pass')), isFalse);
    },
  );

  test('credentials mismatch + terms', () {
    const d = RegistrationDraft(email: 'a@b.co');
    expect(d.validateCredentials('abcd1234', 'abcd12345'), isNotEmpty);
  });
}
