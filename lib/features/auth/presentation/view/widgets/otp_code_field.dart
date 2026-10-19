import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../../../core/resources/qader_design.dart';

/// Reusable five-digit input, including paste, autofill and Arabic numerals.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });
  static const length = 5;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final errorDirection = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = PinTheme(
          width: (constraints.maxWidth - 40) / length,
          height: 50,
          textStyle: const TextStyle(
            fontSize: 20,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF737373),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: QaderDesign.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        );
        return Semantics(
          label: 'otp_code_label'.tr(context: context),
          child: Directionality(
            // A code retains its digit order in both Arabic and English layouts.
            textDirection: TextDirection.ltr,
            child: Pinput(
              length: length,
              controller: controller,
              defaultPinTheme: theme,
              focusedPinTheme: theme.copyDecorationWith(
                border: Border.all(color: QaderDesign.primary),
              ),
              errorPinTheme: theme.copyDecorationWith(
                border: Border.all(color: Theme.of(context).colorScheme.error),
              ),
              separatorBuilder: (_) => const SizedBox(width: 10),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  const arabic = '٠١٢٣٤٥٦٧٨٩';
                  const persian = '۰۱۲۳۴۵۶۷۸۹';
                  final normalized = newValue.text.split('').map((digit) {
                    final value = arabic.indexOf(digit);
                    if (value >= 0) return '$value';
                    final other = persian.indexOf(digit);
                    return other >= 0 ? '$other' : digit;
                  }).join();
                  return newValue.copyWith(
                    text: normalized,
                    composing: TextRange.empty,
                  );
                }),
                FilteringTextInputFormatter.digitsOnly,
              ],
              forceErrorState: errorText != null,
              showErrorWhenFocused: true,
              errorText: errorText,
              errorBuilder: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error ?? '',
                  textDirection: errorDirection,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        );
      },
    );
  }
}
