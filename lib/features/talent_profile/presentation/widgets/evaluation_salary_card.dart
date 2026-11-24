import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../profile_copy.dart';

/// The salary range the reviewer recommends, at the top of the evaluation.
class EvaluationSalaryCard extends StatelessWidget {
  const EvaluationSalaryCard({super.key, required this.salary});
  final SalaryRecommendation salary;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            tc(context, 'Expected Salary Recommendations'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          salaryRangeText(salary),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

/// `2,500–3,200 USD`, or one bound when the other is missing.
String salaryRangeText(SalaryRecommendation salary) {
  final range = [
    if (salary.min case final min?) _amount(min),
    if (salary.max case final max?) _amount(max),
  ].join('–');
  return [range, salary.currency].where((part) => part.isNotEmpty).join(' ');
}

String _amount(num value) => value.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
