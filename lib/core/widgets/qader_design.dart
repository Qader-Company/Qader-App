import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../resources/color_manager.dart';

/// Tokens from the Qader mobile designs; scoped to the new screens.
abstract class QaderDesign {
  static const primary = Color(0xFF0A32DB);
  static const blue = Color(0xFF346AE8);
  static const paleBlue = Color(0xFFF4F8FE);
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF525252);
  static const border = Color(0xFFD4D4D4);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final font = context.locale.languageCode == 'ar' ? 'Rubik' : 'Poppins';
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: font,
        bodyColor: ink,
        displayColor: ink,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: font),
      colorScheme: base.colorScheme.copyWith(primary: primary),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: const Color(0xFF737373),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}

class QaderTheme extends StatelessWidget {
  const QaderTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: QaderDesign.theme(context), child: child);
}

class QaderAsset extends StatelessWidget {
  const QaderAsset(this.name, {super.key, this.width, this.height});
  final String name;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/figma/$name.svg',
    width: width,
    height: height,
    excludeFromSemantics: true,
  );
}

class QaderLogo extends StatelessWidget {
  const QaderLogo({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'app_name'.tr(context: context),
    image: true,
    child: QaderAsset(
      'qader_logo',
      width: large ? 239 : 80,
      height: large ? 102 : 34,
    ),
  );
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Scaffold(
      backgroundColor: ColorManager.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: QaderLogo()),
                  const SizedBox(height: 32),
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

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.tr(context: context),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: title == 'choose_role' ? 32 / 24 : 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle.tr(context: context),
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: QaderDesign.muted,
        ),
      ),
    ],
  );
}

Future<void> showPendingFeature(BuildContext context, String title) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.tr(context: context)),
        content: Text('service_pending'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('confirm'.tr(context: context)),
          ),
        ],
      ),
    );
