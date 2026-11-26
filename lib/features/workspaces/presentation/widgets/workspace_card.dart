import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace.dart';

/// Avatar tints, in turn, like the Figma list (orange, purple, blue).
const _tints = [
  (AppColors.orange50, AppColors.orange600),
  (AppColors.purple50, AppColors.purple600),
  (AppColors.paleBlue, AppColors.blue),
];

/// One workspace of the list; [selected] draws it outlined in blue.
class WorkspaceCard extends StatelessWidget {
  const WorkspaceCard({
    super.key,
    required this.workspace,
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final Workspace workspace;

  /// Position in the list, for the avatar tint.
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (background, color) = _tints[index % _tints.length];
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? Colors.white : AppColors.neutral50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? QaderDesign.blue : AppColors.neutral200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    workspace.initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (workspace.industry.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          workspace.industry,
                          style: const TextStyle(
                            fontSize: 12,
                            color: QaderDesign.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      _MembersChip(
                        count: workspace.membersCount,
                        background: background,
                        color: color,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? QaderDesign.blue : AppColors.neutral300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersChip extends StatelessWidget {
  const _MembersChip({
    required this.count,
    required this.background,
    required this.color,
  });
  final int count;
  final Color background;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          'workspace_members'.tr(
            context: context,
            namedArgs: {'count': '$count'},
          ),
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    ),
  );
}

/// "New workspace" row at the top of the list.
class NewWorkspaceTile extends StatelessWidget {
  const NewWorkspaceTile({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.neutral100,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'workspace_new'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'workspace_new_hint'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
