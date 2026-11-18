import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colors.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';

/// Status filter and date order above the offers list, with
/// "Clear Filters". Choices come from the options endpoint.
class OfferFilters extends StatelessWidget {
  const OfferFilters({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<OffersCubit, OffersState>(
    buildWhen: (a, b) =>
        a.status != b.status ||
        a.sort != b.sort ||
        a.statuses != b.statuses ||
        a.sortOptions != b.sortOptions ||
        a.filtered != b.filtered,
    builder: (context, state) {
      final cubit = context.read<OffersCubit>();
      String statusLabel(String? value) {
        if (value == null) return ot(context, 'all_statuses');
        for (final option in state.statuses) {
          if (option.value == value) {
            return offerStatusText(context, option.value, option.label);
          }
        }
        return offerStatusText(context, value, '');
      }

      String sortLabel(String? value) {
        if (value == null) return ot(context, 'all_dates');
        for (final option in state.sortOptions) {
          if (option.value == value) {
            return offerSortText(context, option.value, option.label);
          }
        }
        return offerSortText(context, value, '');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterMenu(
                  key: const ValueKey('offers-status-filter'),
                  label: statusLabel(state.status),
                  values: [
                    null,
                    for (final option in state.statuses) option.value,
                  ],
                  itemLabel: statusLabel,
                  onSelected: cubit.filterStatus,
                ),
              ),
              if (state.sortOptions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterMenu(
                    key: const ValueKey('offers-date-sort'),
                    label: sortLabel(state.sort),
                    values: [
                      null,
                      for (final option in state.sortOptions) option.value,
                    ],
                    itemLabel: sortLabel,
                    onSelected: cubit.sortBy,
                  ),
                ),
              ],
            ],
          ),
          if (state.filtered)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.blueStrong,
              ),
              onPressed: cubit.clearFilters,
              child: Text(
                ot(context, 'clear_filters'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Outlined button that opens a menu of [values].
class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    super.key,
    required this.label,
    required this.values,
    required this.itemLabel,
    required this.onSelected,
  });
  final String label;
  final List<String?> values;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onSelected;
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
    buildWhen: (a, b) =>
        a.page != b.page || a.lastPage != b.lastPage || a.loading != b.loading,
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
              onPressed: !state.loading && state.page > 1
                  ? () => cubit.goTo(state.page - 1)
                  : null,
            ),
            Expanded(
              child: Text(
                ot(
                  context,
                  'page_of',
                  args: {'page': '${state.page}', 'count': '${state.lastPage}'},
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
              onPressed: !state.loading && state.page < state.lastPage
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
