import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../profile_copy.dart';
import 'evaluation_report_widgets.dart';
import 'evaluation_salary_card.dart';
import 'profile_components.dart';

/// The evaluation report: the salary recommendation, then one collapsible
/// stage for the profile review and one per interview round. The first
/// stage starts open.
class EvaluationContent extends StatefulWidget {
  const EvaluationContent({super.key, required this.evaluation});
  final TalentEvaluation evaluation;
  @override
  State<EvaluationContent> createState() => _EvaluationContentState();
}

class _EvaluationContentState extends State<EvaluationContent> {
  final _open = <int>{0};

  @override
  Widget build(BuildContext context) {
    final profile = widget.evaluation.profileReview;
    final stages = <(String, List<Widget>)>[
      if (profile != null && !profile.isEmpty)
        (tc(context, 'Profile Review'), _profileReview(profile)),
      for (final interview in widget.evaluation.interviews)
        (_interviewTitle(interview), _interview(interview.review)),
    ];
    return ProfileStack(
      gap: 24,
      children: [
        if (profile?.salary case final salary?)
          EvaluationSalaryCard(salary: salary),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => setState(() {
              if (_open.isEmpty) {
                _open.addAll([for (var i = 0; i < stages.length; i++) i]);
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
        for (var i = 0; i < stages.length; i++)
          EvaluationAccordion(
            number: i + 1,
            title: stages[i].$1,
            open: _open.contains(i),
            onTap: () => setState(() {
              if (!_open.remove(i)) _open.add(i);
            }),
            children: stages[i].$2,
          ),
      ],
    );
  }

  String _interviewTitle(InterviewEvaluation interview) {
    final round = 'talent_interview_round'.tr(
      context: context,
      namedArgs: {'round': '${interview.round}'},
    );
    if (interview.type.isEmpty) return round;
    return '${talentCodeLabel(context, '${interview.type}_interview')} · $round';
  }

  List<Widget> _profileReview(EvaluationReview review) => [
    ..._criteria(review),
    ..._reports(review),
    if (review.tips.isNotEmpty) ...[
      const ProfileHeading('Personalized Expert Tips & Guidance'),
      for (final tip in review.tips) ExpertTipCard(tip: tip),
    ],
  ];

  List<Widget> _interview(EvaluationReview review) => [
    if (review.overallScore case final score?)
      Text(
        'talent_overall_score'.tr(
          context: context,
          namedArgs: {'score': '${score.round()}'},
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ..._criteria(review),
    ..._reports(review),
  ];

  List<Widget> _criteria(EvaluationReview review) => [
    if (review.ratings.isNotEmpty) ...[
      Text(
        tc(context, 'Evaluation Criteria'),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      for (final rating in review.ratings.entries)
        EvaluationMetricCard(criterion: rating.key, rating: rating.value),
    ],
  ];

  List<Widget> _reports(EvaluationReview review) => [
    for (final report in review.reports.entries)
      EvaluationTextCard(
        title: talentCodeLabel(context, '${report.key}_report'),
        text: report.value,
      ),
    if (review.finalFeedback case final feedback?)
      EvaluationTextCard(title: tc(context, 'Final Feedback'), text: feedback),
  ];
}
