/// The workspace home: counters and the latest activity.
class WorkspaceDashboard {
  const WorkspaceDashboard({
    this.teamMembers = 0,
    this.activeHiringRequests = 0,
    this.activeContracts = 0,
    this.activeProjects = 0,
    this.recentRequests = const [],
    this.team = const [],
    this.projects = const [],
  });
  final int teamMembers;
  final int activeHiringRequests;
  final int activeContracts;
  final int activeProjects;
  final List<DashboardHiringRequest> recentRequests;
  final List<DashboardMember> team;
  final List<DashboardProject> projects;

  /// Nothing started yet: the dashboard offers ways to build the team.
  bool get isEmpty =>
      recentRequests.isEmpty && team.isEmpty && projects.isEmpty;
}

class DashboardHiringRequest {
  const DashboardHiringRequest({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.postedAt,
    required this.candidates,
  });
  final String title;
  final String subtitle;
  final String statusLabel;
  final DateTime postedAt;
  final int candidates;
}

class DashboardMember {
  const DashboardMember({
    required this.name,
    required this.role,
    required this.statusLabel,
  });
  final String name;
  final String role;
  final String statusLabel;
}

class DashboardProject {
  const DashboardProject({
    required this.name,
    required this.category,
    required this.statusLabel,
    required this.teamSize,
  });
  final String name;
  final String category;
  final String statusLabel;
  final int teamSize;
}
