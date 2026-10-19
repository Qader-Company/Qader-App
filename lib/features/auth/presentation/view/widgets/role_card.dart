import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../../../domain/entities/account_role.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });
  final AccountRole role;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? QaderDesign.paleBlue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? QaderDesign.primary : QaderDesign.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 156),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: QaderAsset(
                          role.name,
                          width: role == AccountRole.talent ? 15.5 : 13.5,
                          height: role == AccountRole.talent ? 19.5 : 21.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        role.name.tr(context: context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      const QaderAsset('radio_selected', width: 20, height: 20)
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: QaderDesign.border),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${role.name}_description'.tr(context: context),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: QaderDesign.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
