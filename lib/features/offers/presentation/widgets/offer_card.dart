import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/hiring_codes.dart';
import '../../domain/entities/hiring_offer_summary.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';

/// One offer in the "My Offers" list.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onOpen});
  final HiringOfferSummary offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final salary = offer.salary;
    final currency = offer.currency;
    final workMode = offer.workMode;
    final received = offer.receivedAt;
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
                  CompanyLogo(
                    name: offer.companyName,
                    imageUrl: offer.companyLogoUrl,
                    square: true,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offer.companyName,
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
              if (offer.jobTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  offer.jobTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              // One chip, as in Figma: in the offer stage the newest offer
              // says more than "Offer" (whose turn it is, or expired).
              if (offer.status == ItemStatus.offer &&
                  offer.latestStatus.isNotEmpty)
                LatestOfferChip(
                  key: const ValueKey('offer-latest-status'),
                  itemStatus: offer.status,
                  status: offer.latestStatus,
                  label: offer.latestStatusLabel,
                  byTalent: offer.latestByTalent,
                )
              else
                OfferStatusChip(value: offer.status, label: offer.statusLabel),
              if (salary != null && currency != null || workMode != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: salary != null && currency != null
                          ? _Fact(
                              label: ot(context, 'salary_monthly'),
                              value: offerMoney(context, salary, currency),
                              highlight: true,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: workMode != null
                          ? _Fact(
                              label: ot(context, 'work_mode'),
                              value: offerCodeLabel(context, workMode),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
              if (received != null) ...[
                const SizedBox(height: 8),
                Text(
                  ot(
                    context,
                    'received_date',
                    args: {'date': offerDate(context, received)},
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
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
