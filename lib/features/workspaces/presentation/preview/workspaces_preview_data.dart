import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_dashboard.dart';
import '../../domain/entities/workspace_lookup.dart';

/// Sample workspace data from the Figma frames, for preview routes only.
abstract final class WorkspacesPreviewData {
  static const workspaces = [
    Workspace(
      id: 'lomee',
      name: 'Lomee Florist',
      industry: 'Flowery Shop',
      membersCount: 12,
    ),
    Workspace(
      id: 'shelf',
      name: 'Shelf spot',
      industry: 'B2B',
      membersCount: 12,
    ),
    Workspace(
      id: 'orascom',
      name: 'Orascom',
      industry: 'B2C',
      membersCount: 12,
    ),
  ];

  static const industries = [
    WorkspaceLookup(id: 1, name: 'Technology'),
    WorkspaceLookup(id: 2, name: 'Retail'),
    WorkspaceLookup(id: 3, name: 'Healthcare'),
  ];

  static const countries = [
    WorkspaceLookup(id: 1, name: 'Egypt'),
    WorkspaceLookup(id: 2, name: 'Saudi Arabia'),
  ];

  static const cities = {
    1: [
      WorkspaceLookup(id: 1, name: 'Cairo'),
      WorkspaceLookup(id: 2, name: 'Alexandria'),
    ],
    2: [
      WorkspaceLookup(id: 3, name: 'Riyadh'),
      WorkspaceLookup(id: 4, name: 'Jeddah'),
    ],
  };

  static const emptyDashboard = WorkspaceDashboard();

  static final dashboard = WorkspaceDashboard(
    teamMembers: 12,
    activeHiringRequests: 2,
    activeContracts: 4,
    activeProjects: 8,
    recentRequests: [
      for (var i = 0; i < 2; i++)
        DashboardHiringRequest(
          title: 'Senior Product Designer',
          subtitle: 'UX/UI • Remote',
          statusLabel: 'Open',
          postedAt: DateTime(2025, 1, 4),
          candidates: 23,
        ),
    ],
    team: [
      for (var i = 0; i < 3; i++)
        const DashboardMember(
          name: 'Mostafa Ali',
          role: 'Product Manager',
          statusLabel: 'Active',
        ),
    ],
    projects: [
      for (var i = 0; i < 3; i++)
        const DashboardProject(
          name: 'Q3 Hiring Sprint',
          category: 'Talent Acquisition',
          statusLabel: 'In Progress',
          teamSize: 4,
        ),
    ],
  );
}
