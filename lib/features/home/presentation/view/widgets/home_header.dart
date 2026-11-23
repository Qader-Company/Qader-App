import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/notification_bell.dart';
import '../../../../../core/widgets/qader_design.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => _HeaderButton(
              asset: 'menu',
              label: 'menu',
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const QaderLogo(),
          const NotificationBell(
            icon: _Circle(
              child: QaderAsset('notification', width: 17.1, height: 17.9),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });
  final String asset;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label.tr(context: context),
    onPressed: onTap,
    icon: _Circle(child: QaderAsset(asset, width: 14.6, height: 12.9)),
  );
}

class _Circle extends StatelessWidget {
  const _Circle({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      color: AppColors.neutral100,
      shape: BoxShape.circle,
    ),
    child: Center(child: child),
  );
}
