import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/qader_design.dart';

/// Figma's Under Review state with sample data until API integration.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.all(24), child: QaderLogo()),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text('home'.tr(context: context)),
                  onTap: () => Navigator.pop(context),
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
        ),
        body: SafeArea(
          child: Column(
            children: [
              ColoredBox(
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
                        onTap: () =>
                            showPendingFeature(context, 'notifications'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    alignment: Alignment.topCenter,
                    color: const Color(0xFFF7F7F7),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0A1F6B),
                                    QaderDesign.primary,
                                    QaderDesign.blue,
                                  ],
                                  stops: [0, .6, 1],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'hello'.tr(context: context),
                                        ),
                                        const TextSpan(
                                          text: 'Olivia Rhye',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'review_title'.tr(context: context),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'review_description'.tr(context: context),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: Color(0xCCFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _ReviewSteps(),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Center(
                                      child: QaderAsset(
                                        'success',
                                        width: 21.5,
                                        height: 21.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'submitted_notice'.tr(context: context),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _ProfileCard(),
                            const SizedBox(height: 24),
                            const _ReviewFaq(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _ReviewSteps extends StatelessWidget {
  const _ReviewSteps();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: 46,
      child: Stack(
        children: [
          PositionedDirectional(
            start: constraints.maxWidth * .148,
            end: constraints.maxWidth * .137,
            top: 34,
            child: const Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: QaderAsset('step_line_active'),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: QaderAsset('step_line_pending'),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final key in ['under_review', 'interviews', 'accepted'])
                Flexible(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          key.tr(context: context),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: key == 'under_review'
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: key == 'under_review'
                                ? QaderDesign.primary
                                : const Color(0xFF737373),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      QaderAsset(
                        key == 'under_review' ? 'step_active' : 'step_pending',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E5E5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [QaderDesign.primary, QaderDesign.blue],
                ),
              ),
              child: const Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olivia Rhye',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 28 / 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'profile_profession'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: QaderDesign.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _ProfileDetail(
          'profile_mail',
          'olivia@untitledui.com',
          width: 12.5,
          height: 10.8,
        ),
        const SizedBox(height: 8),
        const _ProfileDetail(
          'phone',
          '+20 000 000 0000',
          width: 11.4,
          height: 11.4,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ProfileDetail(
                'location',
                'profile_location'.tr(context: context),
                width: 11.4,
                height: 12.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileDetail(
                'language',
                'profile_languages'.tr(context: context),
                width: 12,
                height: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DefaultButton(
          text: 'complete_profile'.tr(context: context),
          height: 34,
          radius: 8,
          color: QaderDesign.paleBlue,
          textColor: QaderDesign.primary,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('profile_locked'.tr(context: context)),
              content: Text('review_description'.tr(context: context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('confirm'.tr(context: context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: .8,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: QaderDesign.primary,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              '80%',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: Color(0xFF737373),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail(
    this.asset,
    this.text, {
    required this.width,
    required this.height,
  });
  final String asset;
  final String text;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 14,
        height: 14,
        child: Center(
          child: QaderAsset(asset, width: width, height: height),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: QaderDesign.muted,
          ),
        ),
      ),
    ],
  );
}

class _ReviewFaq extends StatefulWidget {
  const _ReviewFaq();
  @override
  State<_ReviewFaq> createState() => _ReviewFaqState();
}

class _ReviewFaqState extends State<_ReviewFaq> {
  final Set<int> _expanded = {0};
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'faq_title'.tr(context: context),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _expanded.contains(i),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      if (!_expanded.add(i)) _expanded.remove(i);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'faq_q$i'.tr(context: context),
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: _expanded.contains(i)
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          QaderAsset(
                            _expanded.contains(i)
                                ? 'chevron_up'
                                : 'chevron_down',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_expanded.contains(i))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Text(
                      'faq_a$i'.tr(context: context),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: QaderDesign.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
