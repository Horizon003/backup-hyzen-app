/// Pure, unit-tested validation helpers (no Flutter imports).
class PkPhone {
  PkPhone._();

  /// Accepts 03XXXXXXXXX, 3XXXXXXXXX, +923XXXXXXXXX, 923XXXXXXXXX, with spaces/dashes.
  /// Returns E.164 `+923XXXXXXXXX` or null when invalid.
  static String? normalize(String? input) {
    if (input == null) return null;
    var d = input.trim();
    for (var i = 0; i < 10; i++) {
      d = d.replaceAll(String.fromCharCode(0x0660 + i), '$i').replaceAll(String.fromCharCode(0x06f0 + i), '$i');
    }
    d = d.replaceAll(RegExp(r'[\s\-()\u200b-\u200f\u202a-\u202e]'), '');
    if (d.startsWith('+')) d = d.substring(1);
    if (d.startsWith('0092')) d = d.substring(4);
    if (d.startsWith('92') && d.length == 12) d = d.substring(2);
    if (d.startsWith('0') && d.length == 11) d = d.substring(1);
    if (!RegExp(r'^3[0-9]{9}$').hasMatch(d)) return null;
    return '+92$d';
  }

  static bool isValid(String? input) => normalize(input) != null;

  /// Display form: +92 300 1234567
  static String pretty(String e164) {
    final m = RegExp(r'^\+92(\d{3})(\d{7})$').firstMatch(e164);
    if (m == null) return e164;
    return '+92 ${m.group(1)} ${m.group(2)}';
  }
}

class Validators {
  Validators._();
  static final _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
  );

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? fullName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Full name is required';
    if (s.length < 3) return 'Please enter your full name';
    if (s.length > 80) return 'Name is too long';
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!_email.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Mobile number is required';
    if (!PkPhone.isValid(v)) {
      return 'Use 11 digits, starting with 03';
    }
    return null;
  }

  /// Baseline: min 8 chars, at least one letter and one number.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s)) return 'Include at least one letter';
    if (!RegExp(r'[0-9]').hasMatch(s)) return 'Include at least one number';
    return null;
  }

  static String? confirm(String? v, String original) {
    if ((v ?? '').isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? loginPassword(String? v) =>
      (v ?? '').isEmpty ? 'Password is required' : null;
}
