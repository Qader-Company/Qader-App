import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/workspace.dart';
import '../entities/workspace_dashboard.dart';
import '../entities/workspace_draft.dart';
import '../entities/workspace_lookup.dart';

abstract class WorkspacesRepository {
  Future<Either<Failure, List<Workspace>>> workspaces();
  Future<Either<Failure, Workspace>> create(WorkspaceDraft draft);
  Future<Either<Failure, WorkspaceDashboard>> dashboard(String workspaceId);
  Future<Either<Failure, List<WorkspaceLookup>>> industries();
  Future<Either<Failure, List<WorkspaceLookup>>> countries();
  Future<Either<Failure, List<WorkspaceLookup>>> cities(int countryId);
}
