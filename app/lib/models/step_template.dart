/// Plain data classes for assets/step_templates.json — read-only reference
/// data, not domain state, so no freezed/json_serializable ceremony here.
class StepTemplate {
  const StepTemplate({
    required this.id,
    required this.emoji,
    required this.durationSeconds,
    required this.noExplicitTime,
  });

  final String id;
  final String emoji;
  final int? durationSeconds;
  final bool noExplicitTime;

  factory StepTemplate.fromJson(Map<String, dynamic> json) {
    return StepTemplate(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      noExplicitTime: json['no_explicit_time'] as bool,
    );
  }
}

class StepTemplateCategory {
  const StepTemplateCategory({required this.id, required this.steps});

  final String id;
  final List<StepTemplate> steps;

  factory StepTemplateCategory.fromJson(Map<String, dynamic> json) {
    return StepTemplateCategory(
      id: json['id'] as String,
      steps: (json['steps'] as List)
          .map((s) => StepTemplate.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
