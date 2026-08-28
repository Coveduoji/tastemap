/// 中文日期格式化：「2025-11-03」→「2025年11月03日」。
String formatChineseDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  return '${dt.year}年$mm月$dd日';
}

/// 短格式「2025.11」。
String formatYearMonth(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return '${dt.year}.${dt.month.toString().padLeft(2, '0')}';
}
