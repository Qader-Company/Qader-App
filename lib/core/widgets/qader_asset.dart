import 'package:flutter/material.dart';
import '../resources/assets_manager.dart';
import 'svg_icon.dart';

class QaderAsset extends StatelessWidget {
  const QaderAsset(this.name, {super.key, this.width, this.height});
  final String name;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) => SvgIcon(
    assetPath: '${IconAssets.figmaPath}/$name.svg',
    width: width,
    height: height,
    excludeFromSemantics: true,
  );
}
