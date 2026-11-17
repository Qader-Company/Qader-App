import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_offer.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';

/// One offer in the "My Offers" list.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onOpen});
  final TalentOffer offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final terms = offer.latest;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompanyLogo(name: offer.company.name, square: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offer.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: ot(context, 'view_offer'),
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpen,
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                offer.position,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              OfferStatusChip(OfferStatusFilter.of(offer.stage)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Fact(
                      label: ot(context, 'salary_monthly'),
                      value: offerMoney(context, terms.salary, terms.currency),
                      highlight: true,
                    ),
                  ),
                  Expanded(
                    child: _Fact(
                      label: ot(context, 'work_mode'),
                      value: offerCodeLabel(context, terms.workMode),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ot(
                  context,
                  'received_date',
                  args: {'date': offerDate(context, offer.receivedAt)},
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label, value;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: highlight ? 16 : 13,
          fontWeight: FontWeight.w600,
          color: highlight ? AppColors.blueStrong : AppColors.neutral900,
        ),
      ),
    ],
  );
}
