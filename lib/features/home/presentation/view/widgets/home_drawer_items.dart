import 'package:flutter/material.dart';
import '../../../../../core/resources/qader_design.dart';

const _ink = AppColors.neutral900;
const _muted = AppColors.neutral500;
const _line = AppColors.neutral200;

/// The signed-in talent's initials, name and email at the top of the drawer.
class DrawerProfileHeader extends StatelessWidget {
  const DrawerProfileHeader({
    super.key,
    required this.name,
    required this.email,
  });
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

/// One drawer entry; [small] is used for the design preview links.
class DrawerItem extends StatelessWidget {
  const DrawerItem({
    super.key,
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

/// The line between drawer groups.
class DrawerSeparator extends StatelessWidget {
  const DrawerSeparator({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 33, thickness: 1, color: _line);
}
