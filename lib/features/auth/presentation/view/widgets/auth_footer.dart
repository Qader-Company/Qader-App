import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../domain/entities/account_role.dart';
import 'google_sign_in_button.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.onAction,
    this.registration = false,
    this.role = AccountRole.talent,
    this.onCompanySignUp,
  });
  final VoidCallback onAction;
  final bool registration;
  final AccountRole role;

  /// Shows "Sign up as company" (client sign-in, Figma) when set.
  final VoidCallback? onCompanySignUp;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: registration ? 15 : 16,
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.neutral200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'or'.tr(context: context),
                style: const TextStyle(fontSize: 9),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.neutral200)),
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
          color: AppColors.neutral500,
        ),
      ),
      const SizedBox(height: 12),
      AuthSocialButtons(role: role),
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
      if (onCompanySignUp case final onCompanySignUp?) ...[
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onCompanySignUp,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'sign_up_as_company'.tr(context: context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: QaderDesign.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: GoogleSignInButton(role: role)),
      const SizedBox(width: 12),
      Expanded(
        child: SocialButton(
          provider: 'apple',
          labelKey: 'apple_sign_in',
          onPressed: () => showPendingFeature(context, 'apple_sign_in'),
        ),
      ),
    ],
  );
}
