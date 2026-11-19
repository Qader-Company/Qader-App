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
/// The salary stays in the offer's currency; work type, days and hours
/// are carried over unchanged.
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
  static const _modes = ['remote', 'on_site', 'hybrid'];

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
  late String _mode = _modes.contains(widget.terms.workMode)
      ? widget.terms.workMode
      : _modes.first;
  late final _hybridDays = {...widget.terms.hybridDays};
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
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? ot(context, 'field_required')
      : null;

  void _send() {
    if (!_form.currentState!.validate()) return;
    final terms = widget.terms;
    Navigator.pop(
      context,
      CounterOffer(
        salary: num.parse(_salary.text.trim()),
        currencyId: terms.currencyId,
        workType: terms.workType,
        workMode: _mode,
        firstWorkday: terms.firstWorkday,
        lastWorkday: terms.lastWorkday,
        hybridDays: _mode == 'hybrid'
            ? [
                for (final day in _week)
                  if (_hybridDays.contains(day)) day,
              ]
            : const [],
        hoursPerDay: terms.hoursPerDay,
        noticeDays: _notice,
        location: _location.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat.E(context.locale.toString());
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
            DefaultDropdown<String>(
              compact: true,
              label: ot(context, 'work_mode'),
              initialValue: _mode,
              items: _modes,
              itemLabel: (code) => offerCodeLabel(context, code),
              onChanged: (value) => setState(() => _mode = value ?? _mode),
            ),
            if (_mode == 'hybrid') ...[
              const SizedBox(height: 12),
              FormField<Set<int>>(
                key: ValueKey(_hybridDays.length),
                initialValue: _hybridDays,
                validator: (_) => _hybridDays.isEmpty
                    ? ot(context, 'hybrid_days_invalid')
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ot(context, 'hybrid_days'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final day in _week)
                          FilterChip(
                            label: Text(dayName.format(DateTime(2024, 1, day))),
                            selected: _hybridDays.contains(day),
                            onSelected: (on) => setState(
                              () => on
                                  ? _hybridDays.add(day)
                                  : _hybridDays.remove(day),
                            ),
                          ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DefaultFormField(
              compact: true,
              label: ot(context, 'work_location'),
              controller: _location,
              hint: ot(context, 'work_location_hint'),
              validator: _required,
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
