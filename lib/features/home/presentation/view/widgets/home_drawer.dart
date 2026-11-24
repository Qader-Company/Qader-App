import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_drawer.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/storage/app_preferences.dart';
import '../../../../../core/widgets/language_toggle_button.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../talent_profile/presentation/widgets/profile_previews_sheet.dart';
import '../../current_talent.dart';
import '../../status_copy.dart';
import 'home_drawer_items.dart';
import '../../../../../core/di/maybe_read.dart';

const _muted = AppColors.neutral500;

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    this.preview = true,
    this.current = AppDrawerItem.home,
  });
  final bool preview;
  final AppDrawerItem current;

  void _soon(BuildContext context) {
    Navigator.pop(context);
    showAppToast(context, 'drawer_coming_soon'.tr(context: context));
  }

  void _open(BuildContext context, String route) {
    Navigator.pop(context);
    context.push(route);
  }

  void _settings(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LanguageToggleButton(),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final router = GoRouter.of(context);
    final loggedIn = context.maybeRead<AppPreferences>()?.isLoggedIn ?? false;
    final session = context.maybeRead<AuthSessionCubit>();
    Navigator.pop(context);
    if (loggedIn) await session?.logout();
    router.go(AppRouter.chooseRole);
  }

  void _statusPreviews(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in ApplicationStatus.values)
                ListTile(
                  title: Text(status.label(sheetContext)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      '${AppRouter.statusPreview}?status=${status.name}',
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedName = currentTalentName(context);
    final name = savedName.isNotEmpty
        ? savedName
        : 'drawer_guest'.tr(context: context);
    final email = currentTalentEmail(context);
    return Drawer(
      width: 280,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(topEnd: Radius.circular(16)),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerProfileHeader(name: name, email: email),
            DrawerItem(
              icon: Icons.grid_view_rounded,
              label: 'home'.tr(context: context),
              selected: current == AppDrawerItem.home,
              onTap: current == AppDrawerItem.home
                  ? () => Navigator.pop(context)
                  : () {
                      Navigator.pop(context);
                      context.go(AppRouter.home);
                    },
            ),
            DrawerItem(
              icon: Icons.person_outline_rounded,
              label: 'drawer_my_profile'.tr(context: context),
              selected: current == AppDrawerItem.profile,
              onTap: current == AppDrawerItem.profile
                  ? () => Navigator.pop(context)
                  : () => _open(context, AppRouter.talentProfile),
            ),
            DrawerItem(
              icon: Icons.verified_outlined,
              label: 'drawer_offers'.tr(context: context),
              selected: current == AppDrawerItem.offers,
              onTap: current == AppDrawerItem.offers
                  ? () => Navigator.pop(context)
                  : () => _open(context, AppRouter.offers),
            ),
            const DrawerSeparator(),
            DrawerItem(
              icon: Icons.settings_suggest_outlined,
              label: 'drawer_projects'.tr(context: context),
              onTap: () => _soon(context),
            ),
            DrawerItem(
              icon: Icons.assignment_outlined,
              label: 'drawer_tasks'.tr(context: context),
              onTap: () => _soon(context),
            ),
            DrawerItem(
              icon: Icons.assignment_ind_outlined,
              label: 'drawer_attendance'.tr(context: context),
              onTap: () => _soon(context),
            ),
            const DrawerSeparator(),
            DrawerItem(
              icon: Icons.settings_outlined,
              label: 'drawer_settings'.tr(context: context),
              onTap: () => _settings(context),
            ),
            DrawerItem(
              icon: Icons.logout_rounded,
              label: 'drawer_logout'.tr(context: context),
              onTap: () => _logout(context),
            ),
            if (preview) ...[
              const DrawerSeparator(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 4),
                child: Text(
                  'drawer_design_previews'.tr(context: context),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
              DrawerItem(
                icon: Icons.edit_note_rounded,
                label: 'profile_preview_talent_profile'.tr(context: context),
                small: true,
                onTap: () => _open(context, AppRouter.profileSetup),
              ),
              DrawerItem(
                icon: Icons.preview_outlined,
                label: 'talent_profile_previews'.tr(context: context),
                small: true,
                onTap: () {
                  Navigator.pop(context);
                  showProfilePreviews(context);
                },
              ),
              DrawerItem(
                icon: Icons.local_offer_outlined,
                label: 'drawer_offers_preview'.tr(context: context),
                small: true,
                onTap: () => _open(context, '${AppRouter.offers}?preview=true'),
              ),
              DrawerItem(
                icon: Icons.event_available_outlined,
                label: 'drawer_application_status_previews'.tr(
                  context: context,
                ),
                small: true,
                onTap: () => _statusPreviews(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
