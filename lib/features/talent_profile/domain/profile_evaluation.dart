enum EvaluationLevel { poor, average, good, veryGood }

class EvaluationMetric {
  const EvaluationMetric(this.title, this.score, this.level);
  final String title;
  final int score;
  final EvaluationLevel level;
}

/// Sample UI report, not an assessment of a real account.
class ProfileEvaluation {
  static const metrics = [
    EvaluationMetric('Technical Skills', 35, EvaluationLevel.poor),
    EvaluationMetric('Communication Skills', 50, EvaluationLevel.average),
    EvaluationMetric('Problem Solving', 65, EvaluationLevel.good),
    EvaluationMetric('Soft Skills', 65, EvaluationLevel.veryGood),
  ];
  static const reports = [
    (
      'HR Report',
      'Demonstrates strong knowledge, handling of complex web environments through effective communication, consistency and clear insights. Apply professional examples from previous projects to support your answers.',
    ),
    (
      'Technical Report',
      'Exhibits advanced technical proficiency, with a strong ability to develop complex products and deliver high-quality results. More measurable impact and practical examples would strengthen the technical recommendations.',
    ),
    (
      'Psychology Report',
      'Displays an analytical working style, confidence and openness to feedback. Continue demonstrating how you collaborate and communicate under pressure to support professional growth.',
    ),
    (
      'Final Feedback',
      'The candidate demonstrated strong communication and a clear understanding of the role requirements. Use practical examples with measurable outcomes and structured answers to show how decisions improved product performance and user experience.',
    ),
  ];
  static const tips = [
    'Add measurable outcomes to project descriptions. Explain the problem, your contribution and the result, using numbers such as conversion improvement, time saved or performance gains.',
    'Describe the technical decisions behind each project. Include the tools, team collaboration, challenges and trade-offs so hiring managers can understand your contribution.',
    'Connect each achievement to a business outcome. Replace broad responsibilities with clear examples of what you built, how you measured success and what you learned.',
  ];
}
