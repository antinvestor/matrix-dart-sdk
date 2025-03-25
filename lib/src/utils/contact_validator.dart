final _emailValidatorRegex = RegExp(
  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);

final _msisdnValidatorRegex = RegExp(r'^[+][0-9\-()/.]\s?{6, 15}[0-9]$');

bool isValidEmail(String? email) {
  if (email == null) {
    return false;
  }
  return _emailValidatorRegex.hasMatch(email);
}

bool isValidMsisdn(String? msisdn) {
  if (msisdn == null) {
    return false;
  }
  return _msisdnValidatorRegex.hasMatch(msisdn);
}
