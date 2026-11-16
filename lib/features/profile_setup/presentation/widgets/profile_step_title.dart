import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';

/// Numbered badge and name of the current form step.
class ProfileStepTitle extends StatelessWidget {
  const ProfileStepTitle(this.step, {super.key});
  final int step;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: QaderDesign.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            step.toString(),
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          pc(
            context,
            const [
              '',
              'Basic Info',
              'Skills & Experience',
              'Work Preferences',
            ][step],
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
