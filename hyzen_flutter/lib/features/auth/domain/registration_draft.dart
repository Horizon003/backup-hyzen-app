import '../../../core/utils/validators.dart';
import 'reference_data.dart';
import 'student_profile.dart';

/// Immutable multi-step registration state. Preserved across Back/Next.
/// Password fields are held in memory only and never persisted.
class RegistrationDraft {
  const RegistrationDraft({
    this.fullName = '',
    this.mobile = '',
    this.gender,
    this.city,
    this.customCity = '',
    this.professionalYear,
    this.institutionName = '',
    this.affiliation,
    this.universityId,
    this.customUniversity = '',
    this.customUniversityCity = '',
    this.rollNumber = '',
    this.email = '',
    this.acceptedTerms = false,
    this.photoUrl,
  });

  final String fullName;
  final String mobile;
  final String? gender;
  final String? city; // a known city or 'Other'
  final String customCity;
  final int? professionalYear;
  final String institutionName;
  final AffiliationStatus? affiliation;
  final String? universityId; // known id or ReferenceData.otherId
  final String customUniversity;
  final String customUniversityCity;
  final String rollNumber;
  final String email;
  final bool acceptedTerms;
  final String? photoUrl;

  static const otherCity = 'Other';

  String get resolvedCity =>
      city == otherCity ? customCity.trim() : (city ?? '');

  RegistrationDraft copyWith({
    String? fullName,
    String? mobile,
    String? gender,
    String? city,
    String? customCity,
    int? professionalYear,
    String? institutionName,
    AffiliationStatus? affiliation,
    String? universityId,
    String? customUniversity,
    String? customUniversityCity,
    String? rollNumber,
    String? email,
    bool? acceptedTerms,
    String? photoUrl,
  }) => RegistrationDraft(
    fullName: fullName ?? this.fullName,
    mobile: mobile ?? this.mobile,
    gender: gender ?? this.gender,
    city: city ?? this.city,
    customCity: customCity ?? this.customCity,
    professionalYear: professionalYear ?? this.professionalYear,
    institutionName: institutionName ?? this.institutionName,
    affiliation: affiliation ?? this.affiliation,
    universityId: universityId ?? this.universityId,
    customUniversity: customUniversity ?? this.customUniversity,
    customUniversityCity: customUniversityCity ?? this.customUniversityCity,
    rollNumber: rollNumber ?? this.rollNumber,
    email: email ?? this.email,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    photoUrl: photoUrl ?? this.photoUrl,
  );

  // ---- Step validation (returns map field -> error) ----
  Map<String, String> validatePersonal() {
    final e = <String, String>{};
    final n = Validators.fullName(fullName);
    if (n != null) e['fullName'] = n;
    final p = Validators.phone(mobile);
    if (p != null) e['mobile'] = p;
    if (gender == null) e['gender'] = 'Please select your gender';
    if (city == null) {
      e['city'] = 'Please select your city';
    } else if (city == otherCity && customCity.trim().isEmpty) {
      e['customCity'] = 'Please enter your city';
    }
    if (professionalYear == null) {
      e['professionalYear'] = 'Please select your professional year';
    }
    return e;
  }

  Map<String, String> validateAcademic() {
    final e = <String, String>{};
    if (institutionName.trim().isEmpty) {
      e['institutionName'] = 'College / University name is required';
    }
    if (affiliation == null) e['affiliation'] = 'Please choose an option';
    if (affiliation == AffiliationStatus.affiliated) {
      if (universityId == null) {
        e['universityId'] = 'Please select the affiliated university';
      } else if (universityId == ReferenceData.otherId &&
          customUniversity.trim().isEmpty) {
        e['customUniversity'] = 'University name is required';
      }
    }
    // Roll number is OPTIONAL — never blocks.
    return e;
  }

  Map<String, String> validateCredentials(String password, String confirm) {
    final e = <String, String>{};
    final m = Validators.email(email);
    if (m != null) e['email'] = m;
    final p = Validators.password(password);
    if (p != null) e['password'] = p;
    final c = Validators.confirm(confirm, password);
    if (c != null) e['confirm'] = c;
    if (!acceptedTerms) {
      e['terms'] = 'Please accept the Terms of Use and Privacy Policy';
    }
    return e;
  }

  StudentProfile toProfile(String uid) {
    final affiliated = affiliation == AffiliationStatus.affiliated;
    final known = affiliated
        ? ReferenceData.universityById(universityId)
        : null;
    final isOther = affiliated && universityId == ReferenceData.otherId;
    return StudentProfile(
      uid: uid,
      fullName: fullName.trim(),
      mobile: PkPhone.normalize(mobile)!,
      gender: gender!,
      city: resolvedCity,
      professionalYear: professionalYear!,
      institutionName: institutionName.trim(),
      affiliationStatus: affiliation!,
      affiliatedUniversity: known,
      customUniversity: isOther ? customUniversity.trim() : null,
      customUniversityCity: isOther ? customUniversityCity.trim() : null,
      rollNumber: rollNumber.trim().isEmpty ? null : rollNumber.trim(),
      email: email.trim().toLowerCase(),
      photoUrl: photoUrl,
    );
  }
}
