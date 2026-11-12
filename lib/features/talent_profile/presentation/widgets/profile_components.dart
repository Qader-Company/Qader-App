import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/spaced_column.dart';
export '../../../../core/widgets/spaced_column.dart';
import '../profile_copy.dart';

const profileBlue = AppColors.blueStrong;

/// Profile screens' name for the shared [SpacedColumn].
typedef ProfileStack = SpacedColumn;

class TalentProfileScaffold extends StatelessWidget {
  const TalentProfileScaffold({super.key, required this.child, this.onRefresh});
  final Widget child;

  /// Enables pull to refresh.
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    drawer: AppDrawer.build(current: AppDrawerItem.profile),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _Refreshable(
            onRefresh: onRefresh,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: ProfileStack(
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        tooltip: tc(context, 'Menu'),
                        alignment: AlignmentDirectional.centerStart,
                        padding: EdgeInsets.zero,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const QaderAsset(
                          'menu',
                          width: 14.6,
                          height: 12.9,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tc(context, 'Profile'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tc(context, 'Notifications'),
                      alignment: AlignmentDirectional.centerEnd,
                      onPressed: () =>
                          showPendingFeature(context, 'notifications'),
                      icon: const QaderAsset(
                        'notification',
                        width: 17.1,
                        height: 17.9,
                      ),
                    ),
                  ],
                ),
                DefaultFormField(
                  compact: true,
                  hint: tc(context, 'Search requests, talent, companies'),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.neutral500,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => showInfoDialog(
                    context,
                    titleKey: 'talent_search',
                    messageKey: 'talent_search_pending',
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfileHeading extends StatelessWidget {
  const ProfileHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    tc(context, text),
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
  );
}

/// A labelled value. [label] is translated; [value] is shown as is.
class ProfileDetail extends StatelessWidget {
  const ProfileDetail(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.neutral50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.surfaceMuted),
    ),
    child: ProfileStack(
      gap: 4,
      children: [
        Text(
          tc(context, label),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.neutral500,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 14, height: 1.5)),
      ],
    ),
  );
}

class ProfileTags extends StatelessWidget {
  const ProfileTags(this.values, {super.key});
  final List<String> values;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in values)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: profileBlue,
            ),
          ),
        ),
    ],
  );
}

Future<void> profileNotice(
  BuildContext context,
  String title,
  String message,
) => showInfoDialog(
  context,
  titleKey:
      'talent_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
  messageKey:
      'talent_${message.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
);

/// Opens [url] in the browser. A [preview] profile has no live links, so it
/// explains that with [sampleMessage] instead.
Future<void> openProfileLink(
  BuildContext context, {
  required bool preview,
  required String url,
  required String title,
  required String sampleMessage,
}) async {
  if (preview) return profileNotice(context, title, sampleMessage);
  final uri = Uri.tryParse(url);
  final opened =
      uri != null &&
      uri.hasScheme &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    await profileNotice(context, title, 'Could not open this link');
  }
}

class _Refreshable extends StatelessWidget {
  const _Refreshable({
    required this.onRefresh,
    required this.padding,
    required this.child,
  });
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: child,
    );
    final refresh = onRefresh;
    return refresh == null
        ? scroll
        : RefreshIndicator(onRefresh: refresh, child: scroll);
  }
}
