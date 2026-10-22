import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/language_toggle_button.dart';
import '../../../../talent_profile/presentation/widgets/profile_previews_sheet.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});
  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(24), child: QaderLogo()),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text('home'.tr(context: context)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('profile_preview_talent_profile'.tr(context: context)),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.profileSetup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text('talent_my_profile'.tr(context: context)),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.talentProfile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.preview_outlined),
            title: Text('talent_profile_previews'.tr(context: context)),
            onTap: () {
              Navigator.pop(context);
              showProfilePreviews(context);
            },
          ),
          const LanguageToggleButton(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: Text('back_to_roles'.tr(context: context)),
            onTap: () => context.go(AppRouter.chooseRole),
          ),
        ],
      ),
    ),
  );
}
