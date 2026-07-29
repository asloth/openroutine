import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// UUIDv7 (time-sortable), per docs/SPEC.md §4: "All IDs are UUIDv7."
String newId() => _uuid.v7();
