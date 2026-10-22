import 'package:flutter/material.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../home/presentation/view/widgets/home_drawer.dart';
import '../profile_copy.dart';

const profileBlue = Color(0xFF1D52E5);

class ProfileStack extends StatelessWidget {
  const ProfileStack({super.key, required this.children, this.gap = 16});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}

class TalentProfileScaffold extends StatelessWidget {
  const TalentProfileScaffold({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Scaffold(
      backgroundColor: Colors.white,
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
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
                      color: Color(0xFF737373),
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

class ProfileDetail extends StatelessWidget {
  const ProfileDetail(
    this.label,
    this.value, {
    super.key,
    this.translated = false,
  });
  final String label, value;
  final bool translated;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFF0F0F0)),
    ),
    child: ProfileStack(
      gap: 4,
      children: [
        Text(
          tc(context, label),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF737373),
          ),
        ),
        Text(
          translated ? tc(context, value) : value,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
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
            color: const Color(0xFFF4F8FE),
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
