import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_drawer.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/storage/app_preferences.dart';
import '../../../../../core/widgets/language_toggle_button.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../talent_profile/presentation/widgets/profile_previews_sheet.dart';
import '../../status_copy.dart';

const _ink = AppColors.neutral900;
const _muted = AppColors.neutral500;
const _line = AppColors.neutral200;

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
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(sc(context, 'Coming soon', 'قريباً'))),
      );
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
    Navigator.pop(context);
    if (sl<AppPreferences>().isLoggedIn) await sl<AuthSessionCubit>().logout();
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
    final user = sl.isRegistered<AuthSessionCubit>()
        ? sl<AuthSessionCubit>().state.user
        : null;
    final prefs = sl.isRegistered<AppPreferences>()
        ? sl<AppPreferences>()
        : null;
    final savedName = prefs?.getUserName() ?? '';
    final name = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : savedName.isNotEmpty
        ? savedName
        : sc(context, 'Guest', 'زائر');
    final email = user?.email ?? prefs?.getUserEmail() ?? '';
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
            _Header(name: name, email: email),
            _Item(
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
            _Item(
              icon: Icons.person_outline_rounded,
              label: sc(context, 'My Profile', 'ملفي الشخصي'),
              selected: current == AppDrawerItem.profile,
              onTap: current == AppDrawerItem.profile
                  ? () => Navigator.pop(context)
                  : () => _open(context, AppRouter.talentProfile),
            ),
            _Item(
              icon: Icons.verified_outlined,
              label: sc(context, 'Offers', 'العروض'),
              onTap: () => _soon(context),
            ),
            const _Divider(),
            _Item(
              icon: Icons.settings_suggest_outlined,
              label: sc(context, 'Projects', 'المشاريع'),
              onTap: () => _soon(context),
            ),
            _Item(
              icon: Icons.assignment_outlined,
              label: sc(context, 'Tasks', 'المهام'),
              onTap: () => _soon(context),
            ),
            _Item(
              icon: Icons.assignment_ind_outlined,
              label: sc(context, 'Attendance', 'الحضور'),
              onTap: () => _soon(context),
            ),
            const _Divider(),
            _Item(
              icon: Icons.settings_outlined,
              label: sc(context, 'Settings', 'الإعدادات'),
              onTap: () => _settings(context),
            ),
            _Item(
              icon: Icons.logout_rounded,
              label: sc(context, 'Logout', 'تسجيل الخروج'),
              onTap: () => _logout(context),
            ),
            if (preview) ...[
              const _Divider(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 4),
                child: Text(
                  sc(context, 'Design previews', 'معاينات التصميم'),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
              _Item(
                icon: Icons.edit_note_rounded,
                label: 'profile_preview_talent_profile'.tr(context: context),
                small: true,
                onTap: () => _open(context, AppRouter.profileSetup),
              ),
              _Item(
                icon: Icons.preview_outlined,
                label: 'talent_profile_previews'.tr(context: context),
                small: true,
                onTap: () {
                  Navigator.pop(context);
                  showProfilePreviews(context);
                },
              ),
              _Item(
                icon: Icons.event_available_outlined,
                label: sc(
                  context,
                  'Application status previews',
                  'معاينة حالات الطلب',
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.email});
  final String name;
  final String email;
  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 16, 32),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: QaderDesign.paleBlue,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: QaderDesign.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.small = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final color = selected ? QaderDesign.primary : _ink;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: small ? 10 : 14,
          ),
          child: Row(
            children: [
              Icon(icon, size: small ? 20 : 24, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: small ? 14 : 16,
                    height: 24 / 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 33, thickness: 1, color: _line);
}
