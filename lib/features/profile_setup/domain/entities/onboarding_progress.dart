/// The server decides which step is next; array order is not a progress signal.
class OnboardingProgress {
  const OnboardingProgress({
    required this.completed,
    required this.step,
    required this.steps,
  });
  final bool completed;
  final int step;
  final Map<String, OnboardingProgressStep> steps;
  static const keys = [
    'personal-information',
    'skills-and-experiences',
    'work-preferences',
  ];

  factory OnboardingProgress.fromJson(dynamic raw) {
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      throw const FormatException('Invalid onboarding progress');
    }
    final data = raw['data'] as Map;
    if (data['required_steps_completed'] is! bool || data['steps'] is! List) {
      throw const FormatException('Invalid onboarding progress');
    }
    final steps = <String, OnboardingProgressStep>{};
    for (final item in data['steps'] as List) {
      if (item is! Map ||
          !keys.contains(item['key']) ||
          steps.containsKey(item['key'])) {
        throw const FormatException('Unknown or duplicate onboarding step');
      }
      Set<String> fields(String key) {
        final value = item[key];
        if (value is! List || value.any((v) => v is! String)) {
          throw const FormatException('Invalid onboarding fields');
        }
        return Set<String>.from(value);
      }

      final stepData = item['data'];
      // The API serializes an empty step object as [] for a new talent.
      final emptyArray = stepData is List && stepData.isEmpty;
      if (stepData != null && stepData is! Map && !emptyArray) {
        throw const FormatException('Invalid onboarding step data');
      }
      steps[item['key'] as String] = OnboardingProgressStep(
        visible: fields('visible_fields'),
        required: fields('required_fields'),
        data: stepData is Map ? Map<String, dynamic>.from(stepData) : {},
      );
    }
    if (!keys.every(steps.containsKey)) {
      throw const FormatException('Missing onboarding steps');
    }
    final field = steps[keys.first]!.data['professional_field'];
    final hasField = field is Map && field['id'] is int && field['id'] > 0;
    // Before field selection the API can report 100% with no required fields.
    // Choosing a professional field is still a prerequisite for completion.
    final completed = hasField && data['required_steps_completed'] == true;
    final current = data['current_step'];
    final index = keys.indexOf(current is String ? current : '');
    if (!completed &&
        hasField &&
        index < 0 &&
        current != 'professional-field') {
      throw const FormatException('Unknown current onboarding step');
    }
    return OnboardingProgress(
      completed: completed,
      step: completed
          ? 4
          : !hasField || current == 'professional-field'
          ? 0
          : index + 1,
      steps: steps,
    );
  }
}

class OnboardingProgressStep {
  const OnboardingProgressStep({
    required this.visible,
    required this.required,
    required this.data,
  });
  final Set<String> visible;
  final Set<String> required;
  final Map<String, dynamic> data;
}
