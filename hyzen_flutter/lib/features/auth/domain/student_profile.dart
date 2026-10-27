import 'reference_data.dart';

/// NEW BACKEND EXTENSION — students/{uid}
/// Credentials are owned by Firebase Auth. This document NEVER contains passwords.
enum AffiliationStatus { affiliated, nonAffiliated }

AffiliationStatus? affiliationFrom(Object? v) {
  if (v == 'affiliated') return AffiliationStatus.affiliated;
  if (v == 'non_affiliated') return AffiliationStatus.nonAffiliated;
  return null;
}

String affiliationValue(AffiliationStatus s) =>
    s == AffiliationStatus.affiliated ? 'affiliated' : 'non_affiliated';

class StudentProfile {
  const StudentProfile({
    required this.uid,
    required this.fullName,
    required this.mobile,
    required this.gender,
    required this.city,
    required this.professionalYear,
    required this.institutionName,
    required this.affiliationStatus,
    required this.email,
    this.affiliatedUniversity,
    this.customUniversity,
    this.customUniversityCity,
    this.rollNumber,
    this.photoUrl,
    this.role = 'student',
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String mobile; // E.164 +92XXXXXXXXXX
  final String gender; // male|female|other
  final String city;
  final int professionalYear; // 1..5
  final String institutionName;
  final AffiliationStatus affiliationStatus;
  final University? affiliatedUniversity; // known option
  final String? customUniversity; // when "Other"
  final String? customUniversityCity;
  final String? rollNumber;
  final String email;
  final String? photoUrl;
  final String role; // always 'student' from client
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String? get affiliationDisplay {
    if (affiliationStatus != AffiliationStatus.affiliated) return null;
    if (affiliatedUniversity != null) {
      return '${affiliatedUniversity!.name} (${affiliatedUniversity!.shortName})';
    }
    return customUniversity;
  }

  /// Fields written by the client. createdAt/updatedAt are server timestamps in repository.
  Map<String, dynamic> toWriteMap() => {
    'uid': uid,
    'fullName': fullName.trim(),
    'mobile': mobile,
    'gender': gender,
    'city': city.trim(),
    'professionalYear': professionalYear,
    'institutionName': institutionName.trim(),
    'affiliationStatus': affiliationValue(affiliationStatus),
    'affiliatedUniversity': affiliatedUniversity?.toMap(),
    'customUniversity': (customUniversity ?? '').trim().isEmpty
        ? null
        : customUniversity!.trim(),
    'customUniversityCity': (customUniversityCity ?? '').trim().isEmpty
        ? null
        : customUniversityCity!.trim(),
    'rollNumber': (rollNumber ?? '').trim().isEmpty ? null : rollNumber!.trim(),
    'email': email.trim().toLowerCase(),
    'photoUrl': photoUrl,
    'role': 'student',
  };

  static DateTime? _ts(Object? v) {
    if (v == null) return null;
    try {
      // Firestore Timestamp has toDate(); avoid importing cloud_firestore in domain.
      final d = (v as dynamic).toDate();
      if (d is DateTime) return d;
    } catch (_) {}
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  /// Defensive parsing: never crash on missing/null fields.
  factory StudentProfile.fromMap(String uid, Map<String, dynamic> m) {
    final py = m['professionalYear'];
    return StudentProfile(
      uid: uid,
      fullName: (m['fullName'] as String?) ?? '',
      mobile: (m['mobile'] as String?) ?? '',
      gender: (m['gender'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      professionalYear: py is int ? py : int.tryParse('$py') ?? 1,
      institutionName: (m['institutionName'] as String?) ?? '',
      affiliationStatus:
          affiliationFrom(m['affiliationStatus']) ??
          AffiliationStatus.nonAffiliated,
      affiliatedUniversity: University.fromMap(m['affiliatedUniversity']),
      customUniversity: m['customUniversity'] as String?,
      customUniversityCity: m['customUniversityCity'] as String?,
      rollNumber: m['rollNumber'] as String?,
      email: (m['email'] as String?) ?? '',
      photoUrl: m['photoUrl'] as String?,
      role: (m['role'] as String?) ?? 'student',
      createdAt: _ts(m['createdAt']),
      updatedAt: _ts(m['updatedAt']),
    );
  }

  StudentProfile copyWith({
    String? photoUrl,
    String? fullName,
    String? mobile,
    String? gender,
    String? city,
    int? professionalYear,
    String? institutionName,
    AffiliationStatus? affiliationStatus,
    University? affiliatedUniversity,
    bool clearUniversity = false,
    String? customUniversity,
    String? customUniversityCity,
    String? rollNumber,
  }) {
    return StudentProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      professionalYear: professionalYear ?? this.professionalYear,
      institutionName: institutionName ?? this.institutionName,
      affiliationStatus: affiliationStatus ?? this.affiliationStatus,
      affiliatedUniversity: clearUniversity
          ? affiliatedUniversity
          : (affiliatedUniversity ?? this.affiliatedUniversity),
      customUniversity: clearUniversity
          ? customUniversity
          : (customUniversity ?? this.customUniversity),
      customUniversityCity: clearUniversity
          ? customUniversityCity
          : (customUniversityCity ?? this.customUniversityCity),
      rollNumber: rollNumber ?? this.rollNumber,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
