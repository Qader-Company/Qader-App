import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../domain/entities/hiring_offer_summary.dart';
import '../../domain/repositories/offers_repository.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_card_skeleton.dart';
import '../widgets/offer_filters.dart';
import 'offers_scaffold.dart';

/// "My Offers": the offers sent to the talent, searched, filtered and paged
/// by [repository] (the API, or the preview data for logged-out visitors).
class OffersView extends StatefulWidget {
  const OffersView({super.key, required this.repository, this.preview = false});
  final OffersRepository repository;

  /// Sample offers: cards open the designed details screens.
  final bool preview;
  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  late final _cubit = OffersCubit(widget.repository)..start();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    _cubit.clearFilters();
  }

  void _open(HiringOfferSummary offer) => widget.preview
      ? context.push('${AppRouter.offers}/${offer.id}?preview=true')
      // Get Hiring Offer is not connected yet.
      : showOfferDetailsPending(context);

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    // Statuses and labels come localized from the backend.
    child: LocaleChangeListener(
      onChanged: _cubit.reload,
      child: OffersScaffold(
        onRefresh: _cubit.reload,
        header: AppPageHeader(
          title: ot(context, 'my_offers'),
          searchHint: ot(context, 'search_hint'),
          searchController: _search,
          onSearchChanged: _cubit.search,
        ),
        children: [
          OfferFilters(onClear: _clear),
          BlocBuilder<OffersCubit, OffersState>(
            buildWhen: (a, b) =>
                a.items != b.items ||
                a.loading != b.loading ||
                a.failure != b.failure,
            builder: (context, state) {
              // Placeholder cards on the first load and on every page or
              // filter change, so old results never look current.
              if (state.loading) {
                return OfferListSkeleton(
                  count: state.items.isEmpty
                      ? 3
                      : state.items.length.clamp(1, 4),
                );
              }
              if (state.items.isEmpty && state.failure != null) {
                return _LoadError(onRetry: _cubit.retry);
              }
              if (state.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    ot(context, state.filtered ? 'no_matches' : 'empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final offer in state.items) ...[
                    const SizedBox(height: 12),
                    OfferCard(
                      key: ValueKey('offer-${offer.id}'),
                      offer: offer,
                      onOpen: () => _open(offer),
                    ),
                  ],
                ],
              );
            },
          ),
          const OfferPager(),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
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
          ot(context, 'load_failed'),
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
