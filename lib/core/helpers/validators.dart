import 'package:easy_localization/easy_localization.dart';

class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '${'field_required'.tr()} $fieldName'
          : 'field_required'.tr();
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'email_required'.tr();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'invalid_email'.tr();
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'phone_required'.tr();
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
      return 'invalid_phone'.tr();
    }
    return null;
  }

  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return 'min_length'.tr(args: [min.toString()]);
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value != password) return 'passwords_do_not_match'.tr();
    return null;
  }
}
