import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';

class ApplicationSubmittedNotice extends StatelessWidget {
  const ApplicationSubmittedNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: QaderAsset('success', width: 21.5, height: 21.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'submitted_notice'.tr(context: context),
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
