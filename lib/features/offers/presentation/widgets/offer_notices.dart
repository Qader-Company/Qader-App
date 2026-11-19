import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../offers_copy.dart';

/// Red banner: offer rejected or closed, interview cancelled.
class OfferAlertBanner extends StatelessWidget {
  const OfferAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.cancel_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.red50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.red100),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.red600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red600,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.red500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Blue information box.
class OfferInfoBox extends StatelessWidget {
  const OfferInfoBox(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.blueBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.blueStrong),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.blueStrong,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Amber warning after an offer was closed for no response.
class OfferNoResponseWarning extends StatelessWidget {
  const OfferNoResponseWarning({super.key, required this.chancesLeft});
  final int chancesLeft;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.amber50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.amber200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_rounded, size: 20, color: AppColors.orange600),
        const SizedBox(height: 8),
        Text(
          ot(context, 'warning_title'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.amber800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ot(context, 'warning_message', args: {'count': '$chancesLeft'}),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.amber700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ot(context, 'warning_support'),
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.amber700,
          ),
        ),
      ],
    ),
  );
}
