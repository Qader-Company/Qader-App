import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_overview.dart';

/// The signed contract, waiting for its start date.
class OfferContractCard extends StatelessWidget {
  const OfferContractCard({super.key, required this.contract});
  final OfferContract contract;
  @override
  Widget build(BuildContext context) {
    final days = offerWorkdays(
      context,
      contract.firstWorkday,
      contract.lastWorkday,
    );
    final hours = offerHours(context, contract.workStart, contract.workEnd);
    return OfferPanel(
      title: ot(context, 'contracted_status'),
      children: [
        OfferChip(
          ot(context, 'waiting_to_start'),
          background: AppColors.orange50,
          foreground: AppColors.orange600,
        ),
        const SizedBox(height: 12),
        _Fact(
          ot(context, 'final_salary'),
          '${offerMoney(context, contract.salary, contract.currency, decimals: 2)}'
          ' ${ot(context, 'per_month_long')}',
        ),
        const Divider(height: 24, color: AppColors.neutral200),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Fact(
                ot(context, 'work_mode'),
                offerCodeLabel(context, contract.workMode),
              ),
            ),
            Expanded(
              child: _Fact(
                ot(context, 'work_type'),
                offerCodeLabel(context, contract.workType),
              ),
            ),
          ],
        ),
        if (days != null) ...[
          const SizedBox(height: 12),
          _Fact(ot(context, 'working_days'), days),
        ],
        if (hours != null) ...[
          const SizedBox(height: 12),
          _Fact(ot(context, 'working_hours'), hours),
        ],
        const SizedBox(height: 12),
        _Fact(
          ot(context, 'start_date'),
          DateFormat.yMMMMd(
            context.locale.toString(),
          ).format(contract.startDate),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
