import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/workspaces/domain/entities/workspace.dart';
import 'package:qader/features/workspaces/domain/entities/workspace_dashboard.dart';
import 'package:qader/features/workspaces/domain/entities/workspace_draft.dart';
import 'package:qader/features/workspaces/domain/entities/workspace_lookup.dart';
import 'package:qader/features/workspaces/domain/repositories/workspaces_repository.dart';
import 'package:qader/features/workspaces/presentation/cubit/create_workspace_cubit.dart';
import 'package:qader/features/workspaces/presentation/cubit/workspace_dashboard_cubit.dart';
import 'package:qader/features/workspaces/presentation/cubit/workspaces_cubit.dart';

class _Repo extends Fake implements WorkspacesRepository {
  Failure? failure;
  final cityGates = <int, Completer<void>>{};
  final drafts = <WorkspaceDraft>[];
  Completer<void>? createGate;

  Either<Failure, T> _answer<T>(T value) =>
      failure == null ? Right(value) : Left(failure!);

  @override
  Future<Either<Failure, List<Workspace>>> workspaces() async =>
      _answer(const [Workspace(id: '1', name: 'Lomee Florist')]);

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> industries() async =>
      _answer(const [WorkspaceLookup(id: 1, name: 'Retail')]);

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> countries() async =>
      _answer(const [WorkspaceLookup(id: 1, name: 'Egypt')]);

  @override
  Future<Either<Failure, List<WorkspaceLookup>>> cities(int countryId) async {
    await cityGates[countryId]?.future;
    return _answer([WorkspaceLookup(id: countryId * 10, name: '$countryId')]);
  }

  @override
  Future<Either<Failure, Workspace>> create(WorkspaceDraft draft) async {
    drafts.add(draft);
    await createGate?.future;
    return _answer(Workspace(id: 'new', name: draft.name));
  }

  @override
  Future<Either<Failure, WorkspaceDashboard>> dashboard(
    String workspaceId,
  ) async => _answer(const WorkspaceDashboard(teamMembers: 3));
}

const _draft = WorkspaceDraft(
  name: 'Qader Technology',
  industryIds: [1],
  description: 'Digital products',
  isCompany: false,
  countryId: 1,
  sizeBand: '11-50',
);

void main() {
  test('workspace initials take the first letters of two words', () {
    expect(const Workspace(id: '1', name: 'lomee florist').initials, 'LF');
    expect(const Workspace(id: '2', name: ' Orascom ').initials, 'O');
    expect(const Workspace(id: '3', name: '').initials, '');
  });

  test(
    'the workspace list loads, and keeps its items on a failed reload',
    () async {
      final repo = _Repo();
      final cubit = WorkspacesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.workspaces.single.name, 'Lomee Florist');
      repo.failure = const NetworkFailure(message: 'offline');
      await cubit.load();
      expect(cubit.state.failure?.message, 'offline');
      expect(cubit.state.workspaces, hasLength(1));
    },
  );

  test('the dashboard loads for its workspace', () async {
    final cubit = WorkspaceDashboardCubit(_Repo(), '1');
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.dashboard?.teamMembers, 3);
    expect(cubit.state.dashboard?.isEmpty, isTrue);
  });

  test(
    'the form lists load and a later country wins over a slow one',
    () async {
      final repo = _Repo();
      final cubit = CreateWorkspaceCubit(repo);
      addTearDown(cubit.close);
      await cubit.loadLookups();
      expect(cubit.state.loadingLookups, isFalse);
      expect(cubit.state.industries.single.name, 'Retail');
      expect(cubit.state.countries.single.name, 'Egypt');

      repo.cityGates[1] = Completer<void>();
      final slow = cubit.selectCountry(1);
      await cubit.selectCountry(2);
      repo.cityGates[1]!.complete();
      await slow;
      expect(cubit.state.cities.single.id, 20);
      expect(cubit.state.loadingCities, isFalse);
    },
  );

  test('a failed list load is reported', () async {
    final repo = _Repo()..failure = const ServerFailure(message: 'down');
    final cubit = CreateWorkspaceCubit(repo);
    addTearDown(cubit.close);
    await cubit.loadLookups();
    expect(cubit.state.failure?.message, 'down');
    expect(cubit.state.loadingLookups, isFalse);
  });

  test('submitting creates once and keeps the created workspace', () async {
    final repo = _Repo()..createGate = Completer<void>();
    final cubit = CreateWorkspaceCubit(repo);
    addTearDown(cubit.close);
    final first = cubit.submit(_draft);
    expect(cubit.state.submitting, isTrue);
    await cubit.submit(_draft);
    repo.createGate!.complete();
    await first;
    expect(repo.drafts, hasLength(1));
    expect(cubit.state.created?.name, 'Qader Technology');
    await cubit.submit(_draft);
    expect(repo.drafts, hasLength(1));
  });

  test('a failed submission can be tried again', () async {
    final repo = _Repo()..failure = const ServerFailure(message: 'invalid');
    final cubit = CreateWorkspaceCubit(repo);
    addTearDown(cubit.close);
    await cubit.submit(_draft);
    expect(cubit.state.failure?.message, 'invalid');
    expect(cubit.state.submitting, isFalse);
    repo.failure = null;
    await cubit.submit(_draft);
    expect(cubit.state.created, isNotNull);
  });
}
