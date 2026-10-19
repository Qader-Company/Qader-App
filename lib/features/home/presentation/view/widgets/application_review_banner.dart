import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';

class ApplicationReviewBanner extends StatelessWidget {
  const ApplicationReviewBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1F6B), QaderDesign.primary, QaderDesign.blue],
        stops: [0, .6, 1],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'hello'.tr(context: context)),
              const TextSpan(
                text: 'Olivia Rhye',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'review_title'.tr(context: context),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'review_description'.tr(context: context),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xCCFFFFFF),
          ),
        ),
      ],
    ),
  );
}
