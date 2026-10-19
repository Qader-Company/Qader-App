import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../locale/language_manager.dart';
import '../storage/app_preferences.dart';

/// Changes the locale without replacing the navigator or any page state.
class LanguageToggleButton extends StatefulWidget {
  const LanguageToggleButton({super.key, this.builder});

  final Widget Function(
    BuildContext context,
    VoidCallback? onPressed,
    String targetLanguage,
  )?
  builder;

  @override
  State<LanguageToggleButton> createState() => _LanguageToggleButtonState();
}

class _LanguageToggleButtonState extends State<LanguageToggleButton> {
  bool _changing = false;

  Future<void> _toggle() async {
    if (_changing) return;
    final previous = context.locale;
    final next = previous.languageCode == 'ar' ? englishLocale : arabicLocale;
    final preferences = sl<AppPreferences>();
    setState(() => _changing = true);
    try {
      await preferences.setAppLanguage(next.languageCode);
      if (!mounted) return;
      await context.setLocale(next);
    } catch (_) {
      await preferences.setAppLanguage(previous.languageCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('language_change_failed'.tr(context: context))),
      );
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final targetLanguage = isArabic ? 'English' : 'عربي';
    final onPressed = _changing ? null : _toggle;
    if (widget.builder != null) {
      return widget.builder!(context, onPressed, targetLanguage);
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(targetLanguage),
    );
  }
}
