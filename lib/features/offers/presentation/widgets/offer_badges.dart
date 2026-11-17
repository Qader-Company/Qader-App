import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';

/// Initials logo of a company: a rounded square in the list, a circle on
/// the details page.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, required this.name, this.square = false});
  final String name;
  final bool square;
  @override
  Widget build(BuildContext context) {
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

/// Status of an offer in the list.
class OfferStatusChip extends StatelessWidget {
  const OfferStatusChip(this.status, {super.key});
  final OfferStatusFilter status;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OfferStatusFilter.awaitingResponse ||
      OfferStatusFilter.contracted => (AppColors.green50, AppColors.green700),
      OfferStatusFilter.negotiating ||
      OfferStatusFilter.interview => (AppColors.blueSoft, AppColors.blueStrong),
      OfferStatusFilter.rejected ||
      OfferStatusFilter.cancelled => (AppColors.red50, AppColors.red600),
    };
    return OfferChip(
      offerStatusLabel(context, status),
      background: background,
      foreground: foreground,
    );
  }
}
