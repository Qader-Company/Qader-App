import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final double? width;
  final double? height;
  final String? semanticsLabel;
  final bool excludeFromSemantics;

  const SvgIcon({
    super.key,
    required this.assetPath,
    this.size,
    this.color,
    this.width,
    this.height,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width ?? size,
      height: height ?? size,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
