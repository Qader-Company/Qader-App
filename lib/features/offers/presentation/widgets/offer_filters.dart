import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colors.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';

/// Status and date filters above the offers list.
class OfferFilters extends StatelessWidget {
  const OfferFilters({super.key, required this.onClear});

  /// Also clears the search field the page owns.
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OffersCubit>();
    return BlocBuilder<OffersCubit, OffersState>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.dates != b.dates ||
          a.filtered != b.filtered,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterMenu<OfferStatusFilter?>(
                  key: const ValueKey('offers-status-filter'),
                  label: state.status == null
                      ? ot(context, 'all_statuses')
                      : offerStatusLabel(context, state.status!),
                  values: const [null, ...OfferStatusFilter.values],
                  itemLabel: (value) => value == null
                      ? ot(context, 'all_statuses')
                      : offerStatusLabel(context, value),
                  onSelected: cubit.filterStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterMenu<OfferDateRange>(
                  key: const ValueKey('offers-date-filter'),
                  label: offerDateRangeLabel(context, state.dates),
                  values: OfferDateRange.values,
                  itemLabel: (value) => offerDateRangeLabel(context, value),
                  onSelected: cubit.filterDates,
                ),
              ),
            ],
          ),
          if (state.filtered)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.blueStrong,
              ),
              onPressed: onClear,
              child: Text(
                ot(context, 'clear_filters'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Outlined button that opens a menu of [values].
class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    super.key,
    required this.label,
    required this.values,
    required this.itemLabel,
    required this.onSelected,
  });
  final String label;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: label,
    position: PopupMenuPosition.under,
    onSelected: (index) => onSelected(values[index]),
    itemBuilder: (context) => [
      for (var i = 0; i < values.length; i++)
        PopupMenuItem(value: i, child: Text(itemLabel(values[i]))),
    ],
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.neutral700,
          ),
        ],
      ),
    ),
  );
}

/// Previous / "Page 1 of 2" / Next.
class OfferPager extends StatelessWidget {
  const OfferPager({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<OffersCubit, OffersState>(
    buildWhen: (a, b) => a.page != b.page || a.pageCount != b.pageCount,
    builder: (context, state) {
      final cubit = context.read<OffersCubit>();
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _PagerButton(
              label: ot(context, 'previous'),
              onPressed: state.page > 1
                  ? () => cubit.goTo(state.page - 1)
                  : null,
            ),
            Expanded(
              child: Text(
                ot(
                  context,
                  'page_of',
                  args: {
                    'page': '${state.page}',
                    'count': '${state.pageCount}',
                  },
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral700,
                ),
              ),
            ),
            _PagerButton(
              label: ot(context, 'next'),
              onPressed: state.page < state.pageCount
                  ? () => cubit.goTo(state.page + 1)
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutral700,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: const BorderSide(color: AppColors.neutral300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
