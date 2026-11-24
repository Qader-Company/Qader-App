import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

String tc(BuildContext context, String value) =>
    ('talent_${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '')}')
        .tr(context: context);

/// Label for a talent-profile backend code such as `technical_skills` or
/// `hr_report`: its `talent_<code>` translation when one exists, otherwise
/// the code in title case.
String talentCodeLabel(BuildContext context, String code) {
  final key = 'talent_${code.toLowerCase()}';
  if (key.trExists(context: context)) return key.tr(context: context);
  return _titleCase(code);
}

String _titleCase(String code) => [
  for (final word in code.split('_'))
    if (word.isNotEmpty) '${word[0].toUpperCase()}${word.substring(1)}',
].join(' ');

/// Label for a backend code such as `full_time` or `male`: the profile
/// setup translation when one exists, otherwise the code in title case so
/// a value added by the backend still reads well.
String profileCodeLabel(BuildContext context, String code) {
  final key = 'profile_$code';
  if (key.trExists(context: context)) return key.tr(context: context);
  return _titleCase(code);
}
