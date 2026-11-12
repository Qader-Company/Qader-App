import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../profile_copy.dart';
import 'profile_components.dart';

/// Salary recommendation summary at the top of the evaluation report.
class EvaluationSalaryCard extends StatefulWidget {
  const EvaluationSalaryCard({super.key});
  @override
  State<EvaluationSalaryCard> createState() => _EvaluationSalaryCardState();
}

class _EvaluationSalaryCardState extends State<EvaluationSalaryCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: ProfileStack(
      gap: 8,
      children: [
        Text(
          tc(context, 'Expected Salary Recommendations'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Text(
          '20k–30k',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        Text(
          tc(context, 'Fair Target Annual Salary Average'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: const AlignmentDirectional(-.5, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Text(
              tc(context, 'Market fit'),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const _SalaryBar(),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('15k', style: TextStyle(fontSize: 10)),
            Text('50k', style: TextStyle(fontSize: 10)),
          ],
        ),
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(
            tc(context, 'Your Recommended Position (25K)'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: profileBlue,
            ),
          ),
        ),
        if (_open)
          Text(
            tc(
              context,
              'Improve your profile with measurable achievements, current skills and clear project examples to strengthen your market position.',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.neutral500,
            ),
          ),
      ],
    ),
  );
}

/// Segmented market range: below range, in range, above, far above.
class _SalaryBar extends StatelessWidget {
  const _SalaryBar();
  static const _segments = [
    (18, AppColors.neutral200),
    (47, AppColors.blueStrong),
    (13, AppColors.green500),
    (15, AppColors.red500),
    (7, AppColors.neutral200),
  ];
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      height: 8,
      child: Row(
        // Childless ColoredBoxes have no height of their own.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final segment in _segments)
            Expanded(
              flex: segment.$1,
              child: ColoredBox(color: segment.$2),
            ),
        ],
      ),
    ),
  );
}
