import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/profile_evaluation.dart';
import '../profile_copy.dart';
import 'profile_components.dart';

class EvaluationAccordion extends StatelessWidget {
  const EvaluationAccordion({
    super.key,
    required this.title,
    required this.open,
    required this.onTap,
    required this.children,
  });
  final String title;
  final bool open;
  final VoidCallback onTap;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E5E5)),
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
                  color: open ? profileBlue : const Color(0xFFA3A3A3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tc(context, title),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: open ? profileBlue : const Color(0xFF525252),
                  ),
                ),
              ),
              Icon(
                open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: const Color(0xFF737373),
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
    final color = metric.score < 60
        ? const Color(0xFFF59E0B)
        : const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: ProfileStack(
        gap: 6,
        children: [
          Text(
            tc(context, metric.title),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  tc(context, metric.rating),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
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
              backgroundColor: const Color(0xFFE5E5E5),
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
          color: profileBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB8D0FF)),
        ),
        child: Text(
          tc(context, text),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF525252),
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
    final color = [
      const Color(0xFFF97316),
      profileBlue,
      const Color(0xFF22C55E),
    ][index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: ProfileStack(
        gap: 12,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Color(0xFF22C55E),
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
              color: Color(0xFF737373),
            ),
          ),
        ],
      ),
    );
  }
}
