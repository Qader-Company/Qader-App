import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../offers_copy.dart';

/// "← Back to offers": pops, or opens the list when there is nothing to
/// pop (e.g. a deep link).
class OfferBackLink extends StatelessWidget {
  const OfferBackLink({super.key});
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.neutral900,
      ),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRouter.offers),
      icon: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_forward
            : Icons.arrow_back,
        size: 20,
      ),
      label: Text(
        ot(context, 'back_to_offers'),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
