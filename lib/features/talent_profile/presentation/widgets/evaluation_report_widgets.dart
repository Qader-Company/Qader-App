import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/profile_evaluation.dart';
import '../profile_copy.dart';
import 'profile_components.dart';
import '../../../../core/resources/app_colors.dart';

class EvaluationAccordion extends StatelessWidget {
  const EvaluationAccordion({
    super.key,
    required this.number,
    required this.title,
    required this.open,
    required this.onTap,
    required this.children,
  });
  final int number;
  final String title;
  final bool open;
  final VoidCallback onTap;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: ProfileStack(
      gap: 12,
      children: [
        DefaultButton.compact(
          color: Colors.white,
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: open ? profileBlue : AppColors.neutral400,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tc(context, title),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: open ? profileBlue : AppColors.neutral600,
                  ),
                ),
              ),
              Icon(
                open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.neutral500,
              ),
            ],
          ),
        ),
        if (open) ...children,
      ],
    ),
  );
}

class EvaluationMetricCard extends StatelessWidget {
  const EvaluationMetricCard({super.key, required this.metric});
  final EvaluationMetric metric;
  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (metric.level) {
      EvaluationLevel.poor => (
        'Poor',
        AppColors.yellow100,
        AppColors.yellow700,
      ),
      EvaluationLevel.average => ('AVG', AppColors.red50, AppColors.orange500),
      EvaluationLevel.good => ('Good', AppColors.green50, AppColors.green600),
      EvaluationLevel.veryGood => (
        'VG',
        AppColors.purple50,
        AppColors.purple600,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ProfileStack(
        gap: 8,
        children: [
          Text(
            tc(context, metric.title),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tc(context, label),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${metric.score}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: metric.score / 100,
              minHeight: 6,
              color: profileBlue,
              backgroundColor: AppColors.neutral200,
            ),
          ),
        ],
      ),
    );
  }
}

class EvaluationTextCard extends StatelessWidget {
  const EvaluationTextCard({
    super.key,
    required this.title,
    required this.text,
  });
  final String title, text;
  @override
  Widget build(BuildContext context) => ProfileStack(
    gap: 6,
    children: [
      Text(
        tc(context, title),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.neutral800,
          fontWeight: FontWeight.w500,
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blueLight),
        ),
        child: Text(
          tc(context, text),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.neutral600,
          ),
        ),
      ),
    ],
  );
}

class ExpertTipCard extends StatelessWidget {
  const ExpertTipCard({super.key, required this.text, required this.index});
  final String text;
  final int index;
  @override
  Widget build(BuildContext context) {
    final color = [AppColors.orange500, profileBlue, AppColors.green500][index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ProfileStack(
        gap: 12,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: AppColors.green500,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tc(context, 'High Priority'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            tc(context, 'Enrich Project Details with Numbers and Achievements'),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            tc(context, text),
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
}
