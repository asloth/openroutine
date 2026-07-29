import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/emoji_category.dart';
import '../models/step_template.dart';

part 'reference_data_provider.g.dart';

@riverpod
Future<List<StepTemplateCategory>> stepTemplateCategories(Ref ref) async {
  final raw = await rootBundle.loadString('assets/step_templates.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['templates'] as List)
      .map((t) => StepTemplateCategory.fromJson(t as Map<String, dynamic>))
      .toList();
}

@riverpod
Future<List<EmojiCategory>> emojiCategories(Ref ref) async {
  final raw = await rootBundle.loadString('assets/emojis.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['categories'] as List)
      .map((c) => EmojiCategory.fromJson(c as Map<String, dynamic>))
      .toList();
}
