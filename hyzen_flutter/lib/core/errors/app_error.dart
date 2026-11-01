/// Maps technical errors to friendly copy. Technical detail stays in debug logs only.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address doesn\u2019t look right.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in instead.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this project yet.';
      case 'missing-email':
        return 'Please enter your email address.';
      case 'permission-denied':
        return 'Your account was created, but your profile couldn\u2019t be saved yet. We\u2019ll retry automatically.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class FriendlyException implements Exception {
  FriendlyException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
