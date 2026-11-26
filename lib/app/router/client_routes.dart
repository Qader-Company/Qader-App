import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../features/workspaces/presentation/preview/preview_workspaces_repository.dart';
import '../../features/workspaces/presentation/view/create_workspace_view.dart';
import '../../features/workspaces/presentation/view/workspace_dashboard_view.dart';
import '../../features/workspaces/presentation/view/workspaces_view.dart';

/// Client (employer) routes.
///
/// The workspace screens run on sample data only, until the workspace API's
/// responses are confirmed: they are design previews (`preview=true`), and
/// signed-in clients still land on their account. `empty=true` shows the
/// "no workspace yet" and "nothing started" designs.
final List<RouteBase> clientRoutes = [
  GoRoute(
    path: AppRouter.workspaces,
    builder: (context, state) =>
        WorkspacesView(repository: _preview(state), preview: true),
  ),
  GoRoute(
    path: AppRouter.createWorkspace,
    builder: (context, state) =>
        CreateWorkspaceView(repository: _preview(state), preview: true),
  ),
  GoRoute(
    path: AppRouter.workspaceDashboard,
    builder: (context, state) => WorkspaceDashboardView(
      repository: _preview(state),
      workspaceId: state.uri.queryParameters['id'] ?? '',
      preview: true,
    ),
  ),
];

PreviewWorkspacesRepository _preview(GoRouterState state) =>
    PreviewWorkspacesRepository(
      empty: state.uri.queryParameters['empty'] == 'true',
    );
