import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'qader_asset.dart';

class QaderLogo extends StatelessWidget {
  const QaderLogo({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'app_name'.tr(context: context),
    image: true,
    child: QaderAsset(
      'qader_logo',
      width: large ? 239 : 80,
      height: large ? 102 : 34,
    ),
  );
}
