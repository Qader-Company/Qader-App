import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';

class HomeProfileCard extends StatelessWidget {
  const HomeProfileCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E5E5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [QaderDesign.primary, QaderDesign.blue],
                ),
              ),
              child: const Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olivia Rhye',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 28 / 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'profile_profession'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: QaderDesign.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _ProfileDetail(
          'profile_mail',
          'olivia@untitledui.com',
          width: 12.5,
          height: 10.8,
        ),
        const SizedBox(height: 8),
        const _ProfileDetail(
          'phone',
          '+20 000 000 0000',
          width: 11.4,
          height: 11.4,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ProfileDetail(
                'location',
                'profile_location'.tr(context: context),
                width: 11.4,
                height: 12.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileDetail(
                'language',
                'profile_languages'.tr(context: context),
                width: 12,
                height: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DefaultButton.compact(
          text: 'complete_profile'.tr(context: context),
          height: 34,
          radius: 8,
          color: QaderDesign.paleBlue,
          textColor: QaderDesign.primary,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          onPressed: () => showInfoDialog(
            context,
            titleKey: 'profile_locked',
            messageKey: 'review_description',
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: .8,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: QaderDesign.primary,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              '80%',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: Color(0xFF737373),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail(
    this.asset,
    this.text, {
    required this.width,
    required this.height,
  });
  final String asset;
  final String text;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 14,
        height: 14,
        child: Center(
          child: QaderAsset(asset, width: width, height: height),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: QaderDesign.muted,
          ),
        ),
      ),
    ],
  );
}
