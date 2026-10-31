import 'package:uuid/uuid.dart';

String generateId() => const Uuid().v4();
String nowIso8601() => DateTime.now().toIso8601String();
