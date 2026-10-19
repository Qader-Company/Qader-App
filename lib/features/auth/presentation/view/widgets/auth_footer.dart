import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../../../core/widgets/default_button.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.onAction,
    this.registration = false,
  });
  final VoidCallback onAction;
  final bool registration;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: registration ? 15 : 16,
        child: Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE5E5E5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'or'.tr(context: context),
                style: const TextStyle(fontSize: 9),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE5E5E5))),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        (registration ? 'sign_in_with' : 'sign_up_with').tr(context: context),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: registration ? 1.5 : null,
          fontWeight: registration ? FontWeight.w500 : null,
          color: const Color(0xFF737373),
        ),
      ),
      const SizedBox(height: 12),
      const AuthSocialButtons(),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            (registration ? 'already_have_account' : 'create_account').tr(
              context: context,
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: registration ? 0 : 4,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              (registration ? 'sign_in_link' : 'sign_up').tr(context: context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: registration ? FontWeight.w500 : null,
                color: QaderDesign.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final provider in ['google', 'apple']) ...[
        if (provider == 'apple') const SizedBox(width: 12),
        Expanded(
          child: DefaultButton.compact(
            isOutlined: true,
            color: QaderDesign.border,
            onPressed: () => showPendingFeature(
              context,
              provider == 'google' ? 'google_sign_in' : 'apple_sign_in',
            ),
            child: Semantics(
              label: (provider == 'google' ? 'google_sign_in' : 'apple_sign_in')
                  .tr(context: context),
              child: QaderAsset(provider, width: 20, height: 20),
            ),
          ),
        ),
      ],
    ],
  );
}
