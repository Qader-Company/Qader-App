import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
          _HeaderButton(
            asset: 'notification',
            label: 'notifications',
            onTap: () => showPendingFeature(context, 'notifications'),
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
    icon: Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: QaderAsset(
          asset,
          width: asset == 'menu' ? 14.6 : 17.1,
          height: asset == 'menu' ? 12.9 : 17.9,
        ),
      ),
    ),
  );
}
