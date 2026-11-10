part of '../application_status_view.dart';

// Status dialogs: generic dialog, warning box, reject-slots form.

/// White rounded dialog used by the status screens (Figma "modal").
class _StatusDialog extends StatelessWidget {
  const _StatusDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.centered = false,
  });
  final String title;
  final List<Widget> content;
  final List<Widget> actions;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final close = IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => Navigator.pop(context),
      icon: const QaderAsset('status_close', width: 13, height: 13),
    );
    final heading = Text(
      title,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 28 / 18,
        color: _ink,
      ),
    );
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SpacedColumn(
            gap: 16,
            children: [
              if (centered) ...[
                Align(alignment: AlignmentDirectional.centerEnd, child: close),
                heading,
              ] else
                Row(
                  children: [
                    Expanded(child: heading),
                    close,
                  ],
                ),
              ...content,
              SpacedColumn(gap: 12, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogWarning extends StatelessWidget {
  const _DialogWarning({
    required this.text,
    this.lead,
    this.destructive = false,
  });
  final String text;
  final String? lead;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: destructive ? _redSoft : AppColors.yellow100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QaderAsset(
          destructive ? 'status_warning_red' : 'status_warning_yellow',
          width: 21,
          height: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (lead != null)
                  TextSpan(
                    text: '$lead: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(fontSize: 14, height: 20 / 14, color: _body),
          ),
        ),
      ],
    ),
  );
}

class _RejectSlotsDialog extends StatefulWidget {
  const _RejectSlotsDialog();
  @override
  State<_RejectSlotsDialog> createState() => _RejectSlotsDialogState();
}

class _RejectSlotsDialogState extends State<_RejectSlotsDialog> {
  static const _minLength = 10;
  String reason = '';

  @override
  Widget build(BuildContext context) {
    final missing = _minLength - reason.length;
    return _StatusDialog(
      title: 'status_reject_interview_slots'.tr(context: context),
      content: [
        Text(
          'status_please_explain_why_none_of_the_available'.tr(
            context: context,
          ),
          style: const TextStyle(fontSize: 14, height: 20 / 14, color: _muted),
        ),
        const Divider(height: 1, color: _line),
        _DialogWarning(
          text: 'status_rejecting_all_slots_will_notify_the_qader'.tr(
            context: context,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'status_reason_for_rejection'.tr(context: context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _body,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              onChanged: (value) => setState(() => reason = value.trim()),
              style: const TextStyle(fontSize: 14, color: _ink),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'status_e_g_i_m_unavailable_on_all'.tr(
                  context: context,
                ),
                hintStyle: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.neutral500,
                ),
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: QaderDesign.primary),
                ),
              ),
            ),
            if (missing > 0) ...[
              const SizedBox(height: 6),
              Text(
                'status_more_characters_required'.tr(
                  context: context,
                  namedArgs: {'count': '$missing'},
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, color: _red),
              ),
            ],
          ],
        ),
      ],
      actions: [
        if (missing > 0)
          _disabledButton(
            'status_submit_rejection'.tr(context: context),
            height: 44,
          )
        else
          DefaultButton.compact(
            height: 44,
            text: 'status_submit_rejection'.tr(context: context),
            onPressed: () => Navigator.pop(context, reason.trim()),
          ),
        DefaultButton.compact(
          height: 44,
          isOutlined: true,
          color: _grey,
          textColor: _body,
          text: 'status_cancel'.tr(context: context),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
