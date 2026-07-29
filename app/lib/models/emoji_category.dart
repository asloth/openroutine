/// Plain data class for assets/emojis.json — see step_template.dart for why
/// this isn't a freezed model.
class EmojiCategory {
  const EmojiCategory({required this.id, required this.emojis});

  final String id;
  final List<String> emojis;

  factory EmojiCategory.fromJson(Map<String, dynamic> json) {
    return EmojiCategory(
      id: json['id'] as String,
      emojis: (json['emojis'] as List).cast<String>(),
    );
  }
}
