final _emailValidatorRegex = RegExp(
  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);

final _msisdnValidatorRegex = RegExp(r'^[+][0-9\-()/.]\s?{6, 15}[0-9]$');

final _msisdnCleanupRegex = RegExp(r'[^\d+]');

class ContactUtil {
  static bool isValidEmail(String? email) {
    if (email == null) {
      return false;
    }
    return _emailValidatorRegex.hasMatch(email);
  }

  static bool isValidMsisdn(String? msisdn) {
    if (msisdn == null) {
      return false;
    }
    return _msisdnValidatorRegex.hasMatch(msisdn);
  }

  static String cleanPhoneNumber(String input) {
    // Remove all non-digit and non-plus characters
    final cleaned = input.replaceAll(_msisdnCleanupRegex, '');

    // Remove '+' if not at the start
    final fixed = cleaned.startsWith('+')
        ? '+' + cleaned.substring(1).replaceAll('+', '')
        : cleaned.replaceAll('+', '');

    return fixed;
  }
}
