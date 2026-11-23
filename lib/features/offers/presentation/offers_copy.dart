import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import '../../../core/helpers/feature_dialog.dart';
import '../../../core/resources/app_colors.dart';
import '../domain/entities/talent_offer.dart';

/// `offers_<key>` translated.
String ot(BuildContext context, String key, {Map<String, String>? args}) =>
    'offers_$key'.tr(context: context, namedArgs: args);

/// Label of a backend code such as `remote` or `full_time`; falls back to
/// the code in title case so a new value still reads well.
String offerCodeLabel(BuildContext context, String code) {
  final key = 'offers_code_$code';
  if (key.trExists(context: context)) return key.tr(context: context);
  return [
    for (final word in code.split('_'))
      if (word.isNotEmpty) '${word[0].toUpperCase()}${word.substring(1)}',
  ].join(' ');
}

/// The backend's [label] for a status, or the app's translation of
/// [value] when the label is empty (preview data).
String offerStatusText(BuildContext context, String value, String label) =>
    label.isNotEmpty ? label : ot(context, 'status_$value');

/// Same as [offerStatusText] for a `sort_options` entry.
String offerSortText(BuildContext context, String value, String label) =>
    label.isNotEmpty ? label : ot(context, 'sort_$value');

/// "$6,500" (monthly salaries are whole numbers unless [decimals]).
String offerMoney(
  BuildContext context,
  num amount,
  String currency, {
  int decimals = 0,
}) => NumberFormat.simpleCurrency(
  locale: context.locale.toString(),
  name: currency,
  decimalDigits: decimals,
).format(amount);

/// "Jan 4, 2025".
String offerDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(context.locale.toString()).format(date);

/// "Jan 10, 2025 at 2:30 PM".
String offerDateTime(BuildContext context, DateTime date) => ot(
  context,
  'date_at_time',
  args: {
    'date': offerDate(context, date),
    'time': DateFormat.jm(context.locale.toString()).format(date),
  },
);

/// "Sunday – Thursday", or `null` when a day is missing.
String? offerWorkdays(BuildContext context, int? first, int? last) {
  if (first == null || last == null) return null;
  final format = DateFormat.EEEE(context.locale.toString());
  // 1 Jan 2024 is a Monday, so day N of that week has weekday N.
  return '${format.format(DateTime(2024, 1, first))} – '
      '${format.format(DateTime(2024, 1, last))}';
}

/// "Thursday, Friday", or `null` when there are no days.
String? offerDayNames(BuildContext context, List<int> days) {
  if (days.isEmpty) return null;
  final format = DateFormat.EEEE(context.locale.toString());
  final separator = context.locale.languageCode == 'ar' ? '، ' : ', ';
  return days
      .map((day) => format.format(DateTime(2024, 1, day)))
      .join(separator);
}

/// "9:00 AM – 6:00 PM", or `null` when a time is missing.
String? offerHours(BuildContext context, Duration? start, Duration? end) {
  if (start == null || end == null) return null;
  final format = DateFormat.jm(context.locale.toString());
  final day = DateTime(2024);
  return '${format.format(day.add(start))} – ${format.format(day.add(end))}';
}

String offerNotice(BuildContext context, int days) =>
    ot(context, 'notice_days', args: {'count': '$days'});

/// Asks before an action that cannot be undone. `true` to go ahead.
Future<bool> confirmOfferAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(ot(dialogContext, 'cancel')),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.red600)
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Snackbar after an action: the server's message on failure (or ours
/// for an `offers_` key), [success] otherwise.
void showOfferActionResult(
  BuildContext context, {
  required String? failure,
  required String success,
}) {
  final text = failure == null
      ? success
      : failure.startsWith('offers_')
      ? failure.tr(context: context)
      : failure;
  showAppToast(
    context,
    text,
    type: failure == null ? ToastType.success : ToastType.error,
  );
}

/// Offer actions are designed but the offers API is not connected yet.
Future<void> showOfferActionPending(BuildContext context) => showInfoDialog(
  context,
  titleKey: 'offers_not_connected_title',
  messageKey: 'offers_not_connected_message',
);

extension OfferPartyCopy on OfferParty {
  String title(BuildContext context) => ot(context, 'party_$name');
}
