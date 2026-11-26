import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../cubit/workspaces_cubit.dart';
import '../widgets/workspace_card.dart';
import '../widgets/workspace_failure.dart';
import '../widgets/workspace_intro.dart';
import '../widgets/workspaces_skeleton.dart';

/// Where a client starts: create the first workspace, or pick one to open.
class WorkspacesView extends StatelessWidget {
  const WorkspacesView({
    super.key,
    required this.repository,
    this.preview = false,
  });
  final WorkspacesRepository repository;

  /// Sample data: links keep `preview=true` so the next screens stay samples.
  final bool preview;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WorkspacesCubit(repository)..load(),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<WorkspacesCubit, WorkspacesState>(
          builder: (context, state) {
            if (state.loading && state.workspaces.isEmpty) {
              return const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: WorkspacesSkeleton(),
              );
            }
            if (state.failure case final failure?
                when state.workspaces.isEmpty) {
              return WorkspaceFailure(
                message: failure.message,
                onRetry: context.read<WorkspacesCubit>().load,
              );
            }
            return state.workspaces.isEmpty
                ? _FirstWorkspace(preview: preview)
                : _ChooseWorkspace(
                    workspaces: state.workspaces,
                    preview: preview,
                  );
          },
        ),
      ),
    ),
  );
}

/// [path] with `preview=true` added when [preview].
String withPreview(String path, bool preview) {
  if (!preview) return path;
  return '$path${path.contains('?') ? '&' : '?'}preview=true';
}

class _FirstWorkspace extends StatelessWidget {
  const _FirstWorkspace({required this.preview});
  final bool preview;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              WorkspaceIntro(
                titleKey: 'workspace_first_title',
                subtitleKey: 'workspace_first_hint',
              ),
              SizedBox(height: 32),
              WorkspaceFeatures(),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DefaultButton.compact(
          text: 'workspace_create'.tr(context: context),
          onPressed: () =>
              context.push(withPreview(AppRouter.createWorkspace, preview)),
        ),
      ),
    ],
  );
}

class _ChooseWorkspace extends StatefulWidget {
  const _ChooseWorkspace({required this.workspaces, required this.preview});
  final List<Workspace> workspaces;
  final bool preview;
  @override
  State<_ChooseWorkspace> createState() => _ChooseWorkspaceState();
}

class _ChooseWorkspaceState extends State<_ChooseWorkspace> {
  late String _selected = widget.workspaces.first.id;

  void _open() {
    final id = Uri.encodeQueryComponent(_selected);
    context.go(
      withPreview('${AppRouter.workspaceDashboard}?id=$id', widget.preview),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const WorkspaceIntro(
                      titleKey: 'workspace_choose_title',
                      subtitleKey: 'workspace_choose_hint',
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'workspace_yours'.tr(context: context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'workspace_yours_hint'.tr(context: context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: QaderDesign.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NewWorkspaceTile(
                      onTap: () => context.push(
                        withPreview(AppRouter.createWorkspace, widget.preview),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: widget.workspaces.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final workspace = widget.workspaces[index];
                  return WorkspaceCard(
                    workspace: workspace,
                    index: index,
                    selected: workspace.id == _selected,
                    onTap: () => setState(() => _selected = workspace.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DefaultButton.compact(
          onPressed: _open,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'workspace_open_portal'.tr(context: context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    ],
  );
}
