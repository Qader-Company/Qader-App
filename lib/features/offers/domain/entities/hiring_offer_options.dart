/// One choice of an offers filter, as sent by the backend.
class HiringOfferOption {
  const HiringOfferOption({required this.value, required this.label});

  /// Backend code, e.g. `interview`.
  final String value;

  /// Already localized by the `Accept-Language` header.
  final String label;
}

/// `GET /talent/hiring-offers/options`: the filter choices of the offers
/// list.
class HiringOfferOptions {
  const HiringOfferOptions({
    this.itemStatuses = const [],
    this.offerStatuses = const [],
  });

  /// Where the hiring process stands (`pending`, `offer`, `interview`, …).
  final List<HiringOfferOption> itemStatuses;

  /// Where the offer itself stands (`pending`, `countered`, `expired`, …).
  final List<HiringOfferOption> offerStatuses;

  /// Parses `data`; skips entries without a value or label.
  factory HiringOfferOptions.fromJson(Map<String, dynamic> json) =>
      HiringOfferOptions(
        itemStatuses: _options(json['item_statuses']),
        offerStatuses: _options(json['offer_statuses']),
      );

  static List<HiringOfferOption> _options(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is Map &&
            item['value'] is String &&
            (item['value'] as String).isNotEmpty)
          HiringOfferOption(
            value: item['value'] as String,
            label:
                item['label'] is String &&
                    (item['label'] as String).trim().isNotEmpty
                ? (item['label'] as String).trim()
                : item['value'] as String,
          ),
  ];
}
