import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

String tc(BuildContext context, String value) =>
    ('talent_${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '')}')
        .tr(context: context);
