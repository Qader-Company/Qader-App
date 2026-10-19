extension StringExtensions on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  int get toInt => int.tryParse(this) ?? 0;
  double? toDoubleOrNull() => double.tryParse(this);
  DateTime? toDateTimeOrNull() => DateTime.tryParse(this);

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidPhone => RegExp(r'^\+?[0-9]{8,15}$').hasMatch(this);
}

extension NullableStringExt on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
