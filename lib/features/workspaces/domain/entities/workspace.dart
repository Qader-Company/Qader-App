/// A client workspace as the workspace list and the dashboard show it.
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    this.industry = '',
    this.membersCount = 0,
    this.logoUrl,
  });
  final String id;
  final String name;

  /// Shown under the name on the workspace cards.
  final String industry;
  final int membersCount;
  final String? logoUrl;

  /// Up to two letters for the avatar when there is no logo.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
