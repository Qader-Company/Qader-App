import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_dropdown.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_dialog_frame.dart';

/// The talent's counter offer, as entered in the dialog.
class CounterOfferDraft {
  const CounterOfferDraft({
    required this.salary,
    required this.currency,
    required this.workMode,
    required this.location,
    required this.noticeDays,
    this.hybridDays,
  });
  final num salary;
  final String currency, workMode, location;
  final int noticeDays;
  final int? hybridDays;
}

/// "Submit Counter Offer", prefilled from [terms]. Returns the draft, or
/// `null` when cancelled.
Future<CounterOfferDraft?> showCounterOfferDialog(
  BuildContext context,
  OfferTerms terms,
) => showDialog<CounterOfferDraft>(
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
  static const _currencies = ['USD', 'SAR', 'EGP', 'AED', 'EUR'];
  static const _modes = ['remote', 'on_site', 'hybrid'];
  static const _notices = [0, 7, 14, 30, 60, 90];
  final _form = GlobalKey<FormState>();
  late final _salary = TextEditingController(
    text: widget.terms.salary.toString(),
  );
  final _hybridDays = TextEditingController();
  final _location = TextEditingController();
  late String _currency = _currencies.contains(widget.terms.currency)
      ? widget.terms.currency
      : _currencies.first;
  late String _mode = _modes.contains(widget.terms.workMode)
      ? widget.terms.workMode
      : _modes.first;
  late int _notice = _notices.contains(widget.terms.noticeDays)
      ? widget.terms.noticeDays!
      : 14;

  @override
  void dispose() {
    _salary.dispose();
    _hybridDays.dispose();
    _location.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? ot(context, 'field_required')
      : null;

  void _send() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      CounterOfferDraft(
        salary: num.parse(_salary.text.trim()),
        currency: _currency,
        workMode: _mode,
        location: _location.text.trim(),
        noticeDays: _notice,
        hybridDays: _mode == 'hybrid'
            ? int.parse(_hybridDays.text.trim())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OfferDialogFrame(
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            prefixIcon: PopupMenuButton<String>(
              tooltip: ot(context, 'currency'),
              initialValue: _currency,
              onSelected: (value) => setState(() => _currency = value),
              itemBuilder: (_) => [
                for (final code in _currencies)
                  PopupMenuItem(value: code, child: Text(code)),
              ],
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currency, style: const TextStyle(fontSize: 13)),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DefaultDropdown<String>(
                  compact: true,
                  label: ot(context, 'work_mode'),
                  initialValue: _mode,
                  items: _modes,
                  itemLabel: (code) => offerCodeLabel(context, code),
                  onChanged: (value) => setState(() {
                    _mode = value ?? _mode;
                    if (_mode != 'hybrid') _hybridDays.clear();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DefaultFormField(
                  compact: true,
                  label: ot(context, 'hybrid_days'),
                  controller: _hybridDays,
                  hint: '-',
                  enabled: _mode == 'hybrid',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (_mode != 'hybrid') return null;
                    final days = int.tryParse(value?.trim() ?? '');
                    return days == null || days < 1 || days > 6
                        ? ot(context, 'hybrid_days_invalid')
                        : null;
                  },
                ),
              ),
            ],
          ),
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
            itemLabel: (days) => ot(context, 'notice_option_$days'),
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
