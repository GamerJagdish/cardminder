/// Holds categorized changelog entries grouped by commit types
/// (features, fixes, improvements, maintenance, other).
class CategorizedChangelog {
  final Map<String, List<String>> categories;

  CategorizedChangelog(this.categories);

  bool get isEmpty => categories.isEmpty;
}
