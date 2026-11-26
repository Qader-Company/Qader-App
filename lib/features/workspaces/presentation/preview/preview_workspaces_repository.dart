import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_dashboard.dart';
import '../../domain/entities/workspace_draft.dart';
import '../../domain/entities/workspace_lookup.dart';
import '../../domain/repositories/workspaces_repository.dart';
import 'workspaces_preview_data.dart';

/// Serves [WorkspacesPreviewData] like the API would, for preview routes.
/// Never real account data. With [empty], the client has no workspace yet
/// and the dashboard has nothing started.
class PreviewWorkspacesRepository implements WorkspacesRepository {
  PreviewWorkspacesRepository({this.empty = false});
  final bool empty;

  @override
  Future<Either<Failure, List<Workspace>>> workspaces() async =>
      Right(empty ? const [] : WorkspacesPreviewData.workspaces);

  @override
  Future<Either<Failure, Workspace>> create(WorkspaceDraft draft) async =>
      Right(Workspace(id: 'preview', name: draft.name));

  @override
  Future<Either<Failure, WorkspaceDashboard>> dashboard(
    String workspaceId,
  ) async => Right(
    empty
        ? WorkspacesPreviewData.emptyDashboard
        : WorkspacesPreviewData.dashboard,
  );

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> industries() async =>
      const Right(WorkspacesPreviewData.industries);

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> countries() async =>
      const Right(WorkspacesPreviewData.countries);

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> cities(int countryId) async =>
      Right(WorkspacesPreviewData.cities[countryId] ?? const []);
}
