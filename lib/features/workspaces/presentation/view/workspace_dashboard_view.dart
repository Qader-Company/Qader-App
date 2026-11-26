import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_home_header.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_dashboard.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../cubit/workspace_dashboard_cubit.dart';
import '../widgets/dashboard_activity.dart';
import '../widgets/dashboard_overview.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/workspace_failure.dart';
import 'workspaces_view.dart';

/// The client portal home of one workspace.
class WorkspaceDashboardView extends StatelessWidget {
  const WorkspaceDashboardView({
    super.key,
    required this.repository,
    required this.workspaceId,
    this.preview = false,
  });
  final WorkspacesRepository repository;
  final String workspaceId;
  final bool preview;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WorkspaceDashboardCubit(repository, workspaceId)..load(),
    child: Scaffold(
      backgroundColor: AppColors.neutral50,
      drawer: _WorkspaceDrawer(preview: preview),
      body: SafeArea(
        child: Column(
          children: [
            const AppHomeHeader(),
            Expanded(
              child:
                  BlocBuilder<WorkspaceDashboardCubit, WorkspaceDashboardState>(
                    builder: (context, state) {
                      if (state.dashboard case final dashboard?) {
                        return _Dashboard(dashboard: dashboard);
                      }
                      if (state.failure case final failure?) {
                        return WorkspaceFailure(
                          message: failure.message,
                          onRetry: context.read<WorkspaceDashboardCubit>().load,
                        );
                      }
                      return const SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: DashboardSkeleton(),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.dashboard});
  final WorkspaceDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    // Hiring, the marketplace and assistance come with their own screens.
    void pending(String key) => showPendingFeature(context, key);
    final empty = dashboard.isEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'workspace_welcome'.tr(context: context),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          (empty ? 'workspace_welcome_ready' : 'workspace_welcome_active').tr(
            context: context,
          ),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: QaderDesign.muted,
          ),
        ),
        const SizedBox(height: 16),
        DashboardStats(dashboard: dashboard),
        const SizedBox(height: 24),
        if (empty)
          DashboardBuildTeam(
            onBrowse: () => pending('workspace_browse_talent'),
            onAssistance: () => pending('workspace_get_help'),
          )
        else ...[
          DefaultButton.compact(
            text: 'workspace_new_hiring_request'.tr(context: context),
            icon: const Icon(Icons.add, size: 20, color: Colors.white),
            onPressed: () => pending('workspace_new_hiring_request'),
          ),
          if (dashboard.recentRequests.isNotEmpty) ...[
            const SizedBox(height: 24),
            DashboardSectionHeader(
              titleKey: 'workspace_recent_requests',
              onViewAll: () => pending('workspace_recent_requests'),
            ),
            for (final request in dashboard.recentRequests) ...[
              const SizedBox(height: 12),
              DashboardRequestCard(request: request),
            ],
          ],
          if (dashboard.team.isNotEmpty) ...[
            const SizedBox(height: 24),
            DashboardSectionHeader(
              titleKey: 'workspace_my_team',
              onViewAll: () => pending('workspace_my_team'),
            ),
            const SizedBox(height: 12),
            DashboardTeamCard(team: dashboard.team),
          ],
          if (dashboard.projects.isNotEmpty) ...[
            const SizedBox(height: 24),
            DashboardSectionHeader(
              titleKey: 'workspace_active_projects',
              onViewAll: () => pending('workspace_active_projects'),
            ),
            for (final project in dashboard.projects) ...[
              const SizedBox(height: 12),
              DashboardProjectCard(project: project),
            ],
          ],
        ],
      ],
    );
  }
}

/// Client menu until the full client navigation is designed.
class _WorkspaceDrawer extends StatelessWidget {
  const _WorkspaceDrawer({required this.preview});
  final bool preview;
  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: Colors.white,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: QaderLogo(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text('workspace_switch'.tr(context: context)),
            onTap: () => context.go(withPreview(AppRouter.workspaces, preview)),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: LanguageToggleButton(),
          ),
        ],
      ),
    ),
  );
}
