import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../offers_copy.dart';

/// The offer is gone (404), or a notification pointed at the wrong id:
/// retrying cannot help, so it leads back to the list.
class OfferUnavailable extends StatelessWidget {
  const OfferUnavailable({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
    child: Column(
      children: [
        const Icon(
          Icons.work_off_outlined,
          size: 40,
          color: AppColors.neutral500,
        ),
        const SizedBox(height: 12),
        Text(
          ot(context, 'unavailable_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          ot(context, 'unavailable_message'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 20 / 13,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          text: ot(context, 'back_to_offers'),
          onPressed: () => context.go(AppRouter.offers),
        ),
      ],
    ),
  );
}

/// The offer could not be loaded; [onRetry] loads it again.
class OfferDetailsLoadError extends StatelessWidget {
  const OfferDetailsLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 40,
          color: AppColors.neutral500,
        ),
        const SizedBox(height: 12),
        Text(
          ot(context, 'details_failed'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          text: ot(context, 'try_again'),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
