List<T> parsePaginatedList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (data is List) {
    return data
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
  if (data is Map<String, dynamic> && data['results'] is List) {
    return (data['results'] as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
  return [];
}
