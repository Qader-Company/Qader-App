import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/default_dropdown.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_draft.dart';

/// One social link being typed; the form owns and disposes it.
class SocialLinkInput {
  SocialLinkInput({this.platform = 'linkedin'});
  String platform;
  final url = TextEditingController();
  void dispose() => url.dispose();
}

/// The API's URL rule for social links (scheme optional).
final _socialUrl = RegExp(
  r'^(?:https?://)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}(?::\d{1,5})?(?:[/?#]\S*)?$',
  caseSensitive: false,
);

/// Platform and URL rows with "Add Link" under them.
class WorkspaceSocialLinks extends StatelessWidget {
  const WorkspaceSocialLinks({
    super.key,
    required this.links,
    required this.onAdd,
    required this.onRemove,
    required this.onPlatform,
    this.enabled = true,
  });
  final List<SocialLinkInput> links;
  final VoidCallback onAdd;
  final ValueChanged<SocialLinkInput> onRemove;
  final void Function(SocialLinkInput link, String platform) onPlatform;
  final bool enabled;

  /// The API takes at most 30 links.
  static const maxLinks = 30;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final link in links) ...[
        Row(
          children: [
            Expanded(
              child: DefaultDropdown<String>(
                key: ObjectKey(link),
                initialValue: link.platform,
                compact: true,
                items: workspaceSocialPlatforms,
                itemLabel: (value) =>
                    'workspace_social_$value'.tr(context: context),
                onChanged: enabled
                    ? (value) => onPlatform(link, value ?? link.platform)
                    : null,
              ),
            ),
            if (links.length > 1)
              IconButton(
                tooltip: 'workspace_remove_link'.tr(context: context),
                onPressed: enabled ? () => onRemove(link) : null,
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DefaultFormField(
          compact: true,
          controller: link.url,
          enabled: enabled,
          hint: 'workspace_link_hint'.tr(context: context),
          keyboardType: TextInputType.url,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            return _socialUrl.hasMatch(text)
                ? null
                : 'workspace_invalid_url'.tr(context: context);
          },
        ),
        const SizedBox(height: 12),
      ],
      if (links.length < maxLinks)
        Center(
          child: TextButton.icon(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add, size: 20, color: QaderDesign.blue),
            label: Text(
              'workspace_add_link'.tr(context: context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: QaderDesign.blue,
              ),
            ),
          ),
        ),
    ],
  );
}
