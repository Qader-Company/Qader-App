import 'package:flutter/material.dart';
import '../../domain/profile_evaluation.dart';
import '../profile_copy.dart';
import '../widgets/profile_components.dart';
import '../widgets/evaluation_report_widgets.dart';
import '../widgets/evaluation_salary_card.dart';
import '../../../../core/resources/app_colors.dart';

class ProfileEvaluationView extends StatefulWidget {
  const ProfileEvaluationView({super.key});
  @override
  State<ProfileEvaluationView> createState() => _ProfileEvaluationViewState();
}

class _ProfileEvaluationViewState extends State<ProfileEvaluationView> {
  final _open = <int>{0};
  @override
  Widget build(BuildContext context) => TalentProfileScaffold(
    child: ProfileStack(
      gap: 24,
      children: [
        const EvaluationSalaryCard(),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => setState(() {
              if (_open.isEmpty) {
                _open.addAll([0, 1]);
              } else {
                _open.clear();
              }
            }),
            child: Text(
              tc(context, _open.isEmpty ? 'Expand all' : 'Collapse all'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        ProfileStack(
          gap: 6,
          children: [
            const ProfileHeading('Interview Evaluations'),
            Text(
              tc(context, 'Detailed evaluation criteria for each review stage'),
              style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],
        ),
        EvaluationAccordion(
          number: 1,
          title: 'Profile Review',
          open: _open.contains(0),
          onTap: () => _toggle(0),
          children: [
            Text(
              tc(context, 'Evaluation Criteria'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            for (final metric in ProfileEvaluation.metrics)
              EvaluationMetricCard(metric: metric),
            for (final report in ProfileEvaluation.reports)
              EvaluationTextCard(title: report.$1, text: report.$2),
            const ProfileHeading('Personalized Expert Tips & Guidance'),
            for (var i = 0; i < ProfileEvaluation.tips.length; i++)
              ExpertTipCard(text: ProfileEvaluation.tips[i], index: i),
          ],
        ),
        EvaluationAccordion(
          number: 2,
          title: 'Overall HR Interview',
          open: _open.contains(1),
          onTap: () => _toggle(1),
          children: [
            EvaluationTextCard(
              title: 'HR Report',
              text: ProfileEvaluation.reports.first.$2,
            ),
            for (final metric in ProfileEvaluation.metrics.take(2))
              EvaluationMetricCard(metric: metric),
          ],
        ),
      ],
    ),
  );
  void _toggle(int id) => setState(() {
    if (!_open.remove(id)) _open.add(id);
  });
}
