import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;

  const DefaultAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: getBoldStyle(fontSize: 18.sp, color: ColorManager.textColor),
      ),
      centerTitle: true,
      leading: showBack
          ? leading ??
                IconButton(
                  onPressed: onBack ?? () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: ColorManager.textColor,
                  ),
                )
          : null,
      automaticallyImplyLeading: showBack,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
