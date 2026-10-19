/// Client-side structure and ISO 7064 MOD 97-10 check; the server still
/// validates the destination account before accepting a withdrawal.
class Iban {
  static String normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  static bool isValid(String value) {
    final iban = normalize(value);
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$').hasMatch(iban)) {
      return false;
    }
    // Local markets have fixed national lengths.
    const lengths = {'SA': 24, 'EG': 29, 'AE': 23};
    final length = lengths[iban.substring(0, 2)];
    if (length != null && iban.length != length) return false;
    final check = int.parse(iban.substring(2, 4));
    if (check < 2 || check > 98) return false;
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    var remainder = 0;
    for (final code in rearranged.codeUnits) {
      final value = code >= 65 ? code - 55 : code - 48;
      remainder = (remainder * (value >= 10 ? 100 : 10) + value) % 97;
    }
    return remainder == 1;
  }
}
