/// Backend codes of the talent hiring-offers API, named once so a typo
/// fails to compile instead of silently hiding a state or a button.
///
/// They stay strings, not enums: the backend may add values, and the app
/// must keep working (and show the backend's label) when it does.
library;

/// `status` of a hiring item (`item_statuses` in the options).
abstract final class ItemStatus {
  static const offer = 'offer';
  static const interview = 'interview';
  static const accepted = 'accepted';
  static const onHold = 'on_hold';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
}

/// `offer.status` of one offer (`offer_statuses` in the options, plus the
/// historical `countered`).
abstract final class OfferStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const expired = 'expired';
  static const countered = 'countered';
}

/// `available_actions` of a hiring item.
abstract final class OfferAction {
  static const view = 'view';
  static const accept = 'accept_offer';
  static const reject = 'reject_offer';
  static const counter = 'counter_offer';
}

/// `interview.available_actions`: separate from the item's actions.
abstract final class InterviewAction {
  static const acceptSchedule = 'accept_schedule';
  static const requestChange = 'request_schedule_change';
  static const apologize = 'apologize';
}

/// `proposed_by` of an offer.
abstract final class OfferProposer {
  static const client = 'client';
  static const talent = 'talent';
}
