/// One row of `GET /talent/hiring-offers`: what the offers list shows.
///
/// Built from the item and its `offers` history only; `offer` and
/// `contract_configuration` are not used yet.
class HiringOfferSummary {
  const HiringOfferSummary({
    required this.id,
    required this.status,
    this.statusLabel = '',
    this.reference = '',
    this.companyName = '',
    this.companyLogoUrl,
    this.jobTitle = '',
    this.salary,
    this.currency,
    this.workMode,
    this.receivedAt,
    this.actions = const [],
  });
  final String id;

  /// Backend code of the hiring item, e.g. `offer`, `interview`.
  final String status;

  /// Backend label for [status]; empty means the app translates it.
  final String statusLabel;
  final String reference, companyName, jobTitle;
  final String? companyLogoUrl;

  /// Monthly salary of the newest offer in the history.
  final num? salary;

  /// ISO code, e.g. `EGP`.
  final String? currency;

  /// Backend code, e.g. `hybrid`.
  final String? workMode;

  /// When the client's first offer was sent.
  final DateTime? receivedAt;

  /// `available_actions`, e.g. `view`.
  final List<String> actions;

  /// Parses one entry of `data.items`; `null` when it has no id.
  static HiringOfferSummary? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int && (id is! String || id.isEmpty)) return null;
    final history = [
      for (final item in _list(json['offers']))
        if (_map(item) case final offer?) offer,
    ];
    DateTime? sent(Map<String, dynamic> offer) =>
        _date(offer['sent_at']) ?? _date(offer['created_at']);
    Map<String, dynamic>? newest;
    for (final offer in history) {
      final at = sent(offer);
      final best = newest == null ? null : sent(newest);
      if (newest == null ||
          (at != null && (best == null || at.isAfter(best)))) {
        newest = offer;
      }
    }
    // "Received" is when the client first proposed; any offer otherwise.
    final clientOffers = history.where((o) => o['proposed_by'] == 'client');
    DateTime? received;
    for (final offer in clientOffers.isEmpty ? history : clientOffers) {
      final at = sent(offer);
      if (at != null && (received == null || at.isBefore(received))) {
        received = at;
      }
    }
    final company = _map(json['company']);
    final title = _map(_map(json['talent'])?['job_title']);
    return HiringOfferSummary(
      id: '$id',
      status: _string(json['status']) ?? '',
      statusLabel: _string(json['status_label']) ?? '',
      reference: _string(json['reference']) ?? '',
      companyName: _string(company?['name']) ?? '',
      companyLogoUrl: _string(company?['logo_url']),
      jobTitle: _string(title?['name']) ?? '',
      salary: newest == null ? null : _num(newest['salary_amount']),
      currency: _string(_map(newest?['currency'])?['code']),
      workMode: _string(newest?['work_mode']),
      receivedAt: received,
      actions: _list(json['available_actions']).whereType<String>().toList(),
    );
  }
}

/// One page of the offers list.
class HiringOfferPage {
  const HiringOfferPage({
    required this.items,
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
  });
  final List<HiringOfferSummary> items;
  final int page, lastPage, total;

  /// Parses `data` (`items` and `meta`).
  factory HiringOfferPage.fromJson(Map<String, dynamic> json) {
    final items = [
      for (final item in _list(json['items']))
        if (_map(item) case final raw?)
          if (HiringOfferSummary.fromJson(raw) case final summary?) summary,
    ];
    final meta = _map(json['meta']);
    final page = _num(meta?['current_page'])?.toInt() ?? 1;
    final lastPage = _num(meta?['last_page'])?.toInt() ?? page;
    return HiringOfferPage(
      items: items,
      page: page < 1 ? 1 : page,
      lastPage: lastPage < page ? page : lastPage,
      total: _num(meta?['total'])?.toInt() ?? items.length,
    );
  }
}

/// Search, filter and page of the offers list request.
class HiringOfferQuery {
  const HiringOfferQuery({
    this.search = '',
    this.status,
    this.page = 1,
    this.perPage = 10,
  });
  final String search;

  /// One of the options' `item_statuses`; `null` for every status.
  final String? status;
  final int page, perPage;
}

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;
List<Object?> _list(Object? raw) => raw is List ? raw : const [];
String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
num? _num(Object? raw) => raw is num ? raw : num.tryParse('${raw ?? ''}');
DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
