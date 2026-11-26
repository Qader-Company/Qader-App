import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/resources/qader_design.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleHeight = 1.5,
    this.subtitleArgs,
  });
  final String title;
  final String subtitle;

  /// Values for the `{}` placeholders of [subtitle].
  final List<String>? subtitleArgs;
  final double titleHeight;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.tr(context: context),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: titleHeight,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle.tr(context: context, args: subtitleArgs),
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: QaderDesign.muted,
        ),
      ),
    ],
  );
}
