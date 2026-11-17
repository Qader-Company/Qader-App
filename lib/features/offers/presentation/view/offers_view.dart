import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/talent_offer.dart';
import '../cubit/offers_cubit.dart';
import '../offers_copy.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_filters.dart';
import 'offers_scaffold.dart';

/// "My Offers": the offers sent to the talent, with search, filters and
/// paging. Shows [offers] (the preview data until the API is connected).
class OffersView extends StatefulWidget {
  const OffersView({super.key, required this.offers});
  final List<TalentOffer> offers;
  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  late final _cubit = OffersCubit(widget.offers);
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

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: OffersScaffold(
      current: AppDrawerItem.offers,
      header: AppPageHeader(
        title: ot(context, 'my_offers'),
        searchHint: ot(context, 'search_hint'),
        searchController: _search,
        onSearchChanged: _cubit.search,
      ),
      children: [
        OfferFilters(onClear: _clear),
        BlocBuilder<OffersCubit, OffersState>(
          buildWhen: (a, b) => a.visible != b.visible,
          builder: (context, state) => state.visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    ot(context, state.filtered ? 'no_matches' : 'empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final offer in state.visible) ...[
                      OfferCard(
                        key: ValueKey('offer-${offer.id}'),
                        offer: offer,
                        onOpen: () =>
                            context.push('${AppRouter.offers}/${offer.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
        const OfferPager(),
      ],
    ),
  );
}
