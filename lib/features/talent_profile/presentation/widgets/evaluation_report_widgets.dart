import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../profile_copy.dart';
import 'profile_components.dart';
import '../../../../core/resources/app_colors.dart';

/// A collapsible evaluation stage; [title] is already localized.
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
                  title,
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

/// One criterion rated out of 5 ([criterion] is the backend key, e.g.
/// `technical_skills`), shown as a percentage with a level chip.
class EvaluationMetricCard extends StatelessWidget {
  const EvaluationMetricCard({
    super.key,
    required this.criterion,
    required this.rating,
  });
  final String criterion;
  final num rating;
  @override
  Widget build(BuildContext context) {
    final percent = (rating.clamp(0, 5) * 20).round();
    final (label, background, foreground) = switch (rating.round()) {
      <= 2 => ('Poor', AppColors.yellow100, AppColors.yellow700),
      3 => ('AVG', AppColors.red50, AppColors.orange500),
      4 => ('Good', AppColors.green50, AppColors.green600),
      _ => ('VG', AppColors.purple50, AppColors.purple600),
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
            talentCodeLabel(context, criterion),
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
                '$percent%',
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
              value: percent / 100,
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

/// A titled block of text written by the reviewer; [title] is localized,
/// [text] comes from the backend as is.
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
        title,
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
          text,
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

/// One expert tip with its priority chip.
class ExpertTipCard extends StatelessWidget {
  const ExpertTipCard({super.key, required this.tip});
  final EvaluationTip tip;
  @override
  Widget build(BuildContext context) {
    final color = switch (tip.priority) {
      'high' => AppColors.orange500,
      'low' => AppColors.green500,
      _ => profileBlue,
    };
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
              if (tip.priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    talentCodeLabel(context, '${tip.priority}_priority'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          if (tip.title.isNotEmpty)
            Text(
              tip.title,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (tip.description.isNotEmpty)
            Text(
              tip.description,
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
