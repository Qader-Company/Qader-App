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
    final steps = _steps(data['steps'] as List);
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

  /// Editable snapshot of `GET /talent/profile`: its `data.sections` use the
  /// same shape as the onboarding steps. Opens on the first form step.
  factory OnboardingProgress.fromProfile(dynamic raw) {
    if (raw is! Map ||
        raw['success'] != true ||
        raw['data'] is! Map ||
        (raw['data'] as Map)['sections'] is! List) {
      throw const FormatException('Invalid profile');
    }
    return OnboardingProgress(
      completed: false,
      step: 1,
      steps: _steps((raw['data'] as Map)['sections'] as List),
    );
  }

  static Map<String, OnboardingProgressStep> _steps(List<dynamic> items) {
    final steps = <String, OnboardingProgressStep>{};
    for (final item in items) {
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
        conditional: RequiredWhen.parseAll(item['conditional_required_fields']),
        data: stepData is Map ? Map<String, dynamic>.from(stepData) : {},
      );
    }
    if (!keys.every(steps.containsKey)) {
      throw const FormatException('Missing onboarding steps');
    }
    return steps;
  }
}

class OnboardingProgressStep {
  const OnboardingProgressStep({
    required this.visible,
    required this.required,
    required this.data,
    this.conditional = const [],
  });
  final Set<String> visible;
  final Set<String> required;
  final Map<String, dynamic> data;

  /// `conditional_required_fields`: rules that make a field required only
  /// in some cases. They take precedence over [required].
  final List<RequiredWhen> conditional;
}

/// "[field] is required when [whenField] [operator] [value]", e.g.
/// experiences are required when years_of_experience > 0.
class RequiredWhen {
  const RequiredWhen({
    required this.field,
    required this.whenField,
    required this.operator,
    required this.value,
  });
  final String field, whenField, operator;
  final num value;

  /// Whether the rule applies for [actual]. An unknown operator or a
  /// missing value keeps the field required, as the server would.
  bool holds(num? actual) {
    if (actual == null) return true;
    return switch (operator) {
      '>' => actual > value,
      '>=' => actual >= value,
      '<' => actual < value,
      '<=' => actual <= value,
      '=' || '==' => actual == value,
      '!=' => actual != value,
      _ => true,
    };
  }

  /// Parses the list; skips malformed rules.
  static List<RequiredWhen> parseAll(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is Map && item['required_when'] is Map)
          if (_parse(item, item['required_when'] as Map) case final rule?) rule,
  ];

  static RequiredWhen? _parse(Map item, Map when) {
    final field = item['field'];
    final whenField = when['field'];
    final operator = when['operator'];
    final value = when['value'];
    final number = value is num ? value : num.tryParse('${value ?? ''}');
    if (field is! String ||
        whenField is! String ||
        operator is! String ||
        number == null) {
      return null;
    }
    return RequiredWhen(
      field: field,
      whenField: whenField,
      operator: operator,
      value: number,
    );
  }
}
