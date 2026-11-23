import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/offers_repository.dart';
import '../preview/offers_preview_data.dart';
import '../preview/preview_offers_repository.dart';
import 'live_offer_details_view.dart';
import 'offer_details_view.dart';

/// A sample offer's details for logged-out visitors and design previews.
///
/// Stages the API shape covers go through [LiveOfferDetailsView] backed by
/// sample data, so the real screen is the one being previewed; the rest
/// keep their designed screen ([OfferDetailsView]).
class PreviewOfferDetailsView extends StatelessWidget {
  const PreviewOfferDetailsView({super.key, required this.offerId});
  final String offerId;

  static final _repository = PreviewOffersRepository(OffersPreviewData.offers);

  @override
  Widget build(BuildContext context) {
    if (_repository.servesDetails(offerId)) {
      return RepositoryProvider<OffersRepository>.value(
        value: _repository,
        child: LiveOfferDetailsView(offerId: offerId),
      );
    }
    return OfferDetailsView(offer: OffersPreviewData.byId(offerId)!);
  }
}
