/// Structured reference data for registration (NEW REQUIREMENT, addendum §4).
class University {
  const University({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
  });
  final String id;
  final String name;
  final String shortName;
  final String city;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'city': city,
  };

  static University? fromMap(Object? m) {
    if (m is! Map) return null;
    final id = m['id'];
    if (id is! String) return null;
    return University(
      id: id,
      name: (m['name'] as String?) ?? '',
      shortName: (m['shortName'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
    );
  }
}

class ReferenceData {
  ReferenceData._();

  static const otherId = 'other';

  static const universities = <University>[
    University(
      id: 'pu',
      name: 'University of the Punjab',
      shortName: 'PU',
      city: 'Lahore',
    ),
    University(
      id: 'uos',
      name: 'University of Sargodha',
      shortName: 'UOS',
      city: 'Sargodha',
    ),
    University(
      id: 'bzu',
      name: 'Bahauddin Zakariya University',
      shortName: 'BZU',
      city: 'Multan',
    ),
    University(
      id: 'uhs',
      name: 'University of Health Sciences',
      shortName: 'UHS',
      city: 'Lahore',
    ),
  ];

  static University? universityById(String? id) {
    for (final u in universities) {
      if (u.id == id) return u;
    }
    return null;
  }

  static const professionalYears = <int, String>{
    1: '1st Professional',
    2: '2nd Professional',
    3: '3rd Professional',
    4: '4th Professional',
    5: '5th Professional',
  };

  static String yearLabel(int? y) =>
      professionalYears[y] ?? 'Professional Year';

  static const genders = <String, String>{
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
  };

  /// Pakistani cities (alphabetical). "Other" is handled separately in UI.
  static const cities = <String>[
    'Abbottabad',
    'Astore',
    'Attock',
    'Badin',
    'Bagh',
    'Bahawalnagar',
    'Bahawalpur',
    'Bannu',
    'Batkhela',
    'Bhakkar',
    'Bhalwal',
    'Bhara Kahu',
    'Bhimber',
    'Burewala',
    'Chak Jhumra',
    'Chakwal',
    'Chaman',
    'Charsadda',
    'Chichawatni',
    'Chiniot',
    'Chitral',
    'Dadu',
    'Daska',
    'Depalpur',
    'Dera Allah Yar',
    'Dera Ghazi Khan',
    'Dera Ismail Khan',
    'Dera Murad Jamali',
    'Dipalpur',
    'Faisalabad',
    'Fateh Jang',
    'Fort Abbas',
    'Ghotki',
    'Gilgit',
    'Gojra',
    'Gujar Khan',
    'Gujranwala',
    'Gujrat',
    'Hafizabad',
    'Hangu',
    'Haripur',
    'Harnai',
    'Hasilpur',
    'Haveli Lakha',
    'Hujra Shah Muqeem',
    'Hyderabad',
    'Islamabad',
    'Jacobabad',
    'Jampur',
    'Jamshoro',
    'Jaranwala',
    'Jhang',
    'Jhelum',
    'Kabirwala',
    'Kahuta',
    'Kalat',
    'Kamalia',
    'Kambar',
    'Kamoke',
    'Kandhkot',
    'Karachi',
    'Karak',
    'Kashmore',
    'Kasur',
    'Khairpur',
    'Khanewal',
    'Kharian',
    'Khushab',
    'Kohat',
    'Kot Addu',
    'Kotli',
    'Lahore',
    'Lala Musa',
    'Larkana',
    'Layyah',
    'Lodhran',
    'Loralai',
    'Mandi Bahauddin',
    'Mansehra',
    'Mardan',
    'Matiari',
    'Mian Channu',
    'Mianwali',
    'Minchinabad',
    'Mirpur',
    'Mirpur (AJK)',
    'Mirpur Khas',
    'Moro',
    'Multan',
    'Muridke',
    'Muzaffarabad',
    'Muzaffargarh',
    'Nankana Sahib',
    'Narowal',
    'Nawabshah',
    'Nushki',
    'Okara',
    'Pakpattan',
    'Pattoki',
    'Peshawar',
    'Phalia',
    'Pishin',
    'Qila Saifullah',
    'Quetta',
    'Rahim Yar Khan',
    'Rajanpur',
    'Rawalakot',
    'Rawalpindi',
    'Renala Khurd',
    'Sadiqabad',
    'Sahiwal',
    'Sanghar',
    'Sargodha',
    'Shahdadkot',
    'Shahdadpur',
    'Shakargarh',
    'Shangla',
    'Sheikhupura',
    'Shikarpur',
    'Shorkot',
    'Shujaabad',
    'Sialkot',
    'Skardu',
    'Sohawa',
    'Sukkur',
    'Swabi',
    'Swat',
    'Talagang',
    'Tando Adam',
    'Tando Allahyar',
    'Tando Muhammad Khan',
    'Taxila',
    'Thatta',
    'Timergara',
    'Toba Tek Singh',
    'Turbat',
    'Umerkot',
    'Upper Dir',
    'Vehari',
    'Vihari',
    'Wah Cantt',
    'Wazirabad',
    'Zhob',
  ];
}
