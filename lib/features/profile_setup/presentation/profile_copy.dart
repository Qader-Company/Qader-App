import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String pc(BuildContext context, String text) {
  final key =
      'profile_${text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '')}';
  return key.tr(context: context);
}
