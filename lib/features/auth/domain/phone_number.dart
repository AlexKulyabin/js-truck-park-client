String? normalizePhoneNumberToE164(String rawPhoneNumber) {
  var digits = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('8') && digits.length == 11) {
    digits = '7${digits.substring(1)}';
  }
  if (digits.length < 8 || digits.length > 15) {
    return null;
  }

  return '+$digits';
}
