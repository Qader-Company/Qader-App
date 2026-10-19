import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/helpers/validators.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import 'choose_role_view.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Authentication is deliberately not simulated: no session/token is saved.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('preview_title'.tr(context: context)),
        content: Text('preview_hint'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr(context: context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(
                '${AppRouter.home}?preview=true&role=${widget.role.name}',
              );
            },
            child: Text('preview_home'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeading(title: 'sign_in', subtitle: 'sign_in_hint'),
          const SizedBox(height: 16),
          DefaultFormField(
            labelSpacing: 6,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: Color(0xFF404040),
            ),
            textStyle: const TextStyle(fontSize: 14, height: 20 / 14),
            controller: _email,
            label: 'email'.tr(context: context),
            hint: 'email_hint'.tr(context: context),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) => Validators.email(value?.trim()),
            prefixIcon: const Center(
              widthFactor: 1,
              heightFactor: 1,
              child: QaderAsset('mail', width: 17.9, height: 15.4),
            ),
          ),
          const SizedBox(height: 12),
          DefaultFormField(
            labelSpacing: 6,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: Color(0xFF404040),
            ),
            textStyle: const TextStyle(fontSize: 14, height: 20 / 14),
            controller: _password,
            label: 'password'.tr(context: context),
            hint: 'password_hint'.tr(context: context),
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: Validators.required,
            prefixIcon: const Center(
              widthFactor: 1,
              heightFactor: 1,
              child: QaderAsset('lock', width: 14.6, height: 18),
            ),
            suffixIcon: IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.all(8),
              tooltip: (_obscure ? 'show_password' : 'hide_password').tr(
                context: context,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: _obscure
                  ? const QaderAsset('view_off', width: 16, height: 16)
                  : const Icon(Icons.visibility_outlined, size: 18),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 6),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => showPendingFeature(context, 'forgot_password'),
              child: Text(
                'forgot_password'.tr(context: context),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          DefaultButton(
            text: 'sign_in'.tr(context: context),
            onPressed: _submit,
            height: 40,
            radius: 8,
            fontSize: 14,
            color: QaderDesign.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
          const SizedBox(height: 12),
          Text(
            'sign_up_with'.tr(context: context),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final provider in ['google', 'apple']) ...[
                if (provider == 'apple') const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: QaderDesign.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => showPendingFeature(
                        context,
                        provider == 'google'
                            ? 'google_sign_in'
                            : 'apple_sign_in',
                      ),
                      child: Semantics(
                        label:
                            (provider == 'google'
                                    ? 'google_sign_in'
                                    : 'apple_sign_in')
                                .tr(context: context),
                        child: QaderAsset(provider, width: 20, height: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'create_account'.tr(context: context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () => context.push(
                  '${AppRouter.signUp}?role=${widget.role.name}',
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'sign_up'.tr(context: context),
                  style: const TextStyle(
                    color: QaderDesign.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
