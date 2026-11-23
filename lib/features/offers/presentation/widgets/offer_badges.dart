import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_image.dart';
import '../offers_copy.dart';
import '../../domain/entities/hiring_codes.dart';

/// Company logo, or its initials: a rounded square in the list, a circle
/// on the details page.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.name,
    this.square = false,
    this.imageUrl,
  });
  final String name;
  final bool square;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    if (imageUrl case final url?) {
      return DefaultImage(
        imageUrl: url,
        width: 32,
        height: 32,
        radius: square ? 8 : 16,
      );
    }
    final words = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    // One word: its capitals ("TechCorp" → "TC"), else its first letter.
    final capitals = words.length == 1
        ? RegExp(r'[A-Z]').allMatches(words.single).map((m) => m[0]!).join()
        : '';
    final letters = capitals.length >= 2
        ? capitals.substring(0, 2)
        : words
              .take(2)
              .map((part) => part.characters.first.toUpperCase())
              .join();
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: square ? AppColors.green100 : AppColors.blueStrong,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(8) : null,
      ),
      child: Text(
        letters,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: square ? AppColors.green700 : Colors.white,
        ),
      ),
    );
  }
}

/// A small rounded label with tinted background.
class OfferChip extends StatelessWidget {
  const OfferChip(
    this.text, {
    super.key,
    required this.background,
    required this.foreground,
  });
  final String text;
  final Color background, foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.6,
        color: foreground,
      ),
    ),
  );
}

/// Status of an offer in the list: the backend's [label] (or the
/// translation of [value]), colored by [value].
class OfferStatusChip extends StatelessWidget {
  const OfferStatusChip({super.key, required this.value, this.label = ''});

  /// Backend code (`offer`, `interview`, …) or a preview status.
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (value) {
      // Preview statuses: awaitingResponse, contracted, negotiating.
      ItemStatus.offer ||
      'awaitingResponse' ||
      ItemStatus.accepted ||
      ItemStatus.completed ||
      'contracted' => (AppColors.green50, AppColors.green700),
      ItemStatus.interview ||
      'negotiating' => (AppColors.blueSoft, AppColors.blueStrong),
      ItemStatus.onHold ||
      OfferStatus.pending => (AppColors.amber50, AppColors.amber700),
      ItemStatus.rejected ||
      ItemStatus.cancelled => (AppColors.red50, AppColors.red600),
      _ => (AppColors.neutral100, AppColors.neutral700),
    };
    return OfferChip(
      offerStatusText(context, value, label),
      background: background,
      foreground: foreground,
    );
  }
}
