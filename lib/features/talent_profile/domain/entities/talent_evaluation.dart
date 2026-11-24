/// The talent's evaluation from `GET /talent/profile/evaluation`: the
/// review of the profile and one review per completed interview.
class TalentEvaluation {
  const TalentEvaluation({this.profileReview, this.interviews = const []});

  final EvaluationReview? profileReview;
  final List<InterviewEvaluation> interviews;

  factory TalentEvaluation.fromJson(Map<String, dynamic> json) {
    final profile = json['profile_review'];
    return TalentEvaluation(
      profileReview: profile is Map
          ? EvaluationReview.fromJson(Map<String, dynamic>.from(profile))
          : null,
      interviews: [
        for (final item in json['interview_reviews'] as List? ?? const [])
          if (item is Map && item['evaluation'] is Map)
            InterviewEvaluation.fromJson(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => a.round.compareTo(b.round)),
    );
  }
}

/// One review: ratings out of 5 by criterion (backend keys such as
/// `technical_skills`, in the backend's order), reports by kind (`hr`,
/// `technical`, `psychology`) and, depending on the review, a salary
/// recommendation, tips, an overall score and final feedback.
class EvaluationReview {
  const EvaluationReview({
    this.ratings = const {},
    this.averageRating,
    this.overallScore,
    this.salary,
    this.reports = const {},
    this.finalFeedback,
    this.tips = const [],
  });

  final Map<String, num> ratings;
  final num? averageRating;

  /// Out of 100.
  final num? overallScore;
  final SalaryRecommendation? salary;
  final Map<String, String> reports;
  final String? finalFeedback;
  final List<EvaluationTip> tips;

  factory EvaluationReview.fromJson(Map<String, dynamic> json) {
    final ratings = json['ratings'];
    final reports = json['reports'];
    final salary = json['recommended_salary'];
    final feedback = _text(json['final_feedback']);
    return EvaluationReview(
      ratings: {
        if (ratings is Map)
          for (final entry in ratings.entries)
            if (_number(entry.value) case final value?) '${entry.key}': value,
      },
      averageRating: _number(json['average_rating']),
      overallScore: _number(json['overall_score']),
      salary: salary is Map
          ? SalaryRecommendation.fromJson(Map<String, dynamic>.from(salary))
          : null,
      reports: {
        if (reports is Map)
          for (final entry in reports.entries)
            if (_text(entry.value).isNotEmpty)
              '${entry.key}': _text(entry.value),
      },
      finalFeedback: feedback.isEmpty ? null : feedback,
      tips: [
        for (final item in json['tips'] as List? ?? const [])
          if (item is Map)
            EvaluationTip.fromJson(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  bool get isEmpty =>
      ratings.isEmpty &&
      reports.isEmpty &&
      tips.isEmpty &&
      finalFeedback == null &&
      overallScore == null;
}

/// A recommended salary range; [min] and [max] are amounts in [currency].
class SalaryRecommendation {
  const SalaryRecommendation({this.min, this.max, this.currency = ''});
  final num? min, max;

  /// ISO code, e.g. `USD`.
  final String currency;

  factory SalaryRecommendation.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    return SalaryRecommendation(
      min: _number(json['min']),
      max: _number(json['max']),
      currency: currency is Map ? _text(currency['code']) : _text(currency),
    );
  }
}

/// Advice for the talent; [priority] is a backend code such as `high`.
class EvaluationTip {
  const EvaluationTip({
    required this.title,
    required this.description,
    this.priority = '',
    this.order = 0,
  });
  final String title, description, priority;
  final int order;

  factory EvaluationTip.fromJson(Map<String, dynamic> json) => EvaluationTip(
    title: _text(json['title']),
    description: _text(json['description']),
    priority: _text(json['priority']),
    order: _number(json['display_order'])?.toInt() ?? 0,
  );
}

/// The review of one interview round; [type] is a backend code such as
/// `technical` or `hr`.
class InterviewEvaluation {
  const InterviewEvaluation({
    required this.round,
    required this.review,
    this.type = '',
    this.completedAt,
  });
  final int round;
  final String type;
  final DateTime? completedAt;
  final EvaluationReview review;

  factory InterviewEvaluation.fromJson(Map<String, dynamic> json) =>
      InterviewEvaluation(
        round: _number(json['round_number'])?.toInt() ?? 1,
        type: _text(json['type']),
        completedAt: DateTime.tryParse(_text(json['completed_at']))?.toLocal(),
        review: EvaluationReview.fromJson(
          Map<String, dynamic>.from(json['evaluation'] as Map),
        ),
      );
}

String _text(Object? value) => value == null ? '' : '$value'.trim();

num? _number(Object? value) =>
    value is num ? value : num.tryParse(_text(value));
