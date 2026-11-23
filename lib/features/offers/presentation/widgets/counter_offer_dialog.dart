import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_dropdown.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../domain/entities/counter_offer.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_dialog_frame.dart';

/// "Submit Counter Offer", prefilled from [terms]. Returns the counter
/// offer, or `null` when cancelled.
///
/// Only the salary and the notice period can change: work mode, office
/// days and location are shown locked and sent as offered, like the
/// currency, work type, days and hours.
Future<CounterOffer?> showCounterOfferDialog(
  BuildContext context,
  OfferTerms terms,
) => showDialog<CounterOffer>(
  context: context,
  barrierColor: AppColors.barrier,
  builder: (_) => _CounterOfferDialog(terms: terms),
);

class _CounterOfferDialog extends StatefulWidget {
  const _CounterOfferDialog({required this.terms});
  final OfferTerms terms;
  @override
  State<_CounterOfferDialog> createState() => _CounterOfferDialogState();
}

class _CounterOfferDialogState extends State<_CounterOfferDialog> {
  /// Saturday first, as the work week reads in the region.
  static const _week = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];
  final _form = GlobalKey<FormState>();
  late final _salary = TextEditingController(
    text: NumberFormat('0.##').format(widget.terms.salary),
  );
  late final _location = TextEditingController(
    text: widget.terms.location ?? '',
  );
  final _hybridText = TextEditingController();
  late final _mode = TextEditingController();
  late final _notices = {
    0,
    7,
    14,
    30,
    60,
    90,
    if (widget.terms.noticeDays case final days?) days,
  }.toList()..sort();
  late int _notice = widget.terms.noticeDays ?? 14;

  @override
  void dispose() {
    _salary.dispose();
    _location.dispose();
    _hybridText.dispose();
    _mode.dispose();
    super.dispose();
  }

  bool get _hybrid => widget.terms.workMode == 'hybrid';

  /// The offer's office days in week order ("Sun, Thu"), "-" when it is
  /// not hybrid.
  List<int> get _officeDays => [
    for (final day in _week)
      if (_hybrid && widget.terms.hybridDays.contains(day)) day,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Labels follow the language, so they are set here, not in build.
    final terms = widget.terms;
    _mode.text = terms.workMode.isEmpty
        ? '-'
        : offerCodeLabel(context, terms.workMode);
    final name = DateFormat.E(context.locale.toString());
    final days = _officeDays;
    _hybridText.text = days.isEmpty
        ? '-'
        : days.map((day) => name.format(DateTime(2024, 1, day))).join(', ');
  }

  void _send() {
    if (!_form.currentState!.validate()) return;
    final terms = widget.terms;
    Navigator.pop(
      context,
      CounterOffer(
        salary: num.parse(_salary.text.trim()),
        currencyId: terms.currencyId,
        workType: terms.workType,
        workMode: terms.workMode,
        firstWorkday: terms.firstWorkday,
        lastWorkday: terms.lastWorkday,
        hybridDays: _officeDays,
        hoursPerDay: terms.hoursPerDay,
        noticeDays: _notice,
        location: _location.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OfferDialogFrame(
      title: ot(context, 'counter_title'),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultFormField(
              key: const ValueKey('counter-salary'),
              compact: true,
              label: ot(context, 'salary_monthly'),
              controller: _salary,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    widget.terms.currency,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              validator: (value) {
                final amount = num.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? ot(context, 'salary_invalid')
                    : null;
              },
            ),
            const SizedBox(height: 12),
            // As in Figma: office days sit beside the work mode. Both,
            // and the location, are the offer's own and cannot change.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DefaultFormField(
                    key: const ValueKey('counter-work-mode'),
                    compact: true,
                    enabled: false,
                    label: ot(context, 'work_mode'),
                    controller: _mode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DefaultFormField(
                    key: const ValueKey('counter-hybrid-days'),
                    compact: true,
                    enabled: false,
                    label: ot(context, 'hybrid_days'),
                    controller: _hybridText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultFormField(
              key: const ValueKey('counter-location'),
              compact: true,
              enabled: false,
              label: ot(context, 'work_location'),
              controller: _location,
            ),
            const SizedBox(height: 12),
            DefaultDropdown<int>(
              compact: true,
              label: ot(context, 'availability_notice'),
              initialValue: _notice,
              items: _notices,
              itemLabel: (days) => switch (days) {
                0 ||
                7 ||
                14 ||
                30 ||
                60 ||
                90 => ot(context, 'notice_option_$days'),
                _ => offerNotice(context, days),
              },
              onChanged: (value) => setState(() => _notice = value ?? _notice),
            ),
            const SizedBox(height: 20),
            DefaultButton.compact(
              text: ot(context, 'send_counter'),
              onPressed: _send,
            ),
            const SizedBox(height: 10),
            DefaultButton.compact(
              text: ot(context, 'cancel'),
              isOutlined: true,
              color: AppColors.neutral300,
              textColor: AppColors.neutral700,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
