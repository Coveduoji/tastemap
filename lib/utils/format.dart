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

/// Compact map heading, using the real administrative district when available.
String formatMapArea({
  String? city,
  String? province,
  String? district,
  String? country,
}) {
  final areas = [city, province, country]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final area = areas.isEmpty ? null : areas.first;
  final local = district?.trim() ?? '';
  if (area == null) return local.isEmpty ? '地图' : local;
  return local.isEmpty || local == area ? area : '$area · $local';
}
