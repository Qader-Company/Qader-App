import 'package:flutter/widgets.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../profile_copy.dart';

/// Sample evaluation for the profile previews (signed out, or opened from
/// the preview screens), never shown as a real talent's assessment. Its
/// texts are translated, unlike a real evaluation's, which come from the
/// reviewer as written.
TalentEvaluation previewEvaluation(BuildContext context) {
  String t(String value) => tc(context, value);
  final reports = {
    'hr': t(
      'Demonstrates strong knowledge, handling of complex web environments through effective communication, consistency and clear insights. Apply professional examples from previous projects to support your answers.',
    ),
    'technical': t(
      'Exhibits advanced technical proficiency, with a strong ability to develop complex products and deliver high-quality results. More measurable impact and practical examples would strengthen the technical recommendations.',
    ),
    'psychology': t(
      'Displays an analytical working style, confidence and openness to feedback. Continue demonstrating how you collaborate and communicate under pressure to support professional growth.',
    ),
  };
  final title = t('Enrich Project Details with Numbers and Achievements');
  return TalentEvaluation(
    profileReview: EvaluationReview(
      ratings: const {
        'technical_skills': 2,
        'communication_skills': 3,
        'problem_solving': 4,
        'soft_skills': 5,
      },
      salary: const SalaryRecommendation(
        min: 20000,
        max: 30000,
        currency: 'EGP',
      ),
      reports: reports,
      finalFeedback: t(
        'The candidate demonstrated strong communication and a clear understanding of the role requirements. Use practical examples with measurable outcomes and structured answers to show how decisions improved product performance and user experience.',
      ),
      tips: [
        for (final (priority, text) in [
          (
            'high',
            'Add measurable outcomes to project descriptions. Explain the problem, your contribution and the result, using numbers such as conversion improvement, time saved or performance gains.',
          ),
          (
            'medium',
            'Describe the technical decisions behind each project. Include the tools, team collaboration, challenges and trade-offs so hiring managers can understand your contribution.',
          ),
          (
            'low',
            'Connect each achievement to a business outcome. Replace broad responsibilities with clear examples of what you built, how you measured success and what you learned.',
          ),
        ])
          EvaluationTip(title: title, description: t(text), priority: priority),
      ],
    ),
    interviews: [
      InterviewEvaluation(
        round: 1,
        type: 'hr',
        review: EvaluationReview(
          ratings: const {'technical_skills': 2, 'communication_skills': 3},
          overallScore: 70,
          reports: {'hr': reports['hr']!},
        ),
      ),
    ],
  );
}
