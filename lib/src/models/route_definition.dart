/// Route definition model
class RouteDefinition {
  final String path;
  final String? name;
  final String? description;
  final String? screenClass;
  final DateTime lastUpdated;

  const RouteDefinition({
    required this.path,
    this.name,
    this.description,
    this.screenClass,
    required this.lastUpdated,
  });

  List<String> toRow() {
    return [
      path,
      name ?? '',
      description ?? '',
      screenClass ?? '',
      _formatDate(lastUpdated),
    ];
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteDefinition &&
        other.path == path &&
        other.name == name &&
        other.description == description &&
        other.screenClass == screenClass;
  }

  @override
  int get hashCode => Object.hash(path, name, description, screenClass);
}
