import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../resources/app_colors.dart';
import 'spaced_column.dart';

/// Countdown to when a rejected profile can be re-evaluated / reapply.

class ProfileReevaluationCountdown extends StatefulWidget {
  const ProfileReevaluationCountdown({super.key, required this.deadline});
  final DateTime deadline;
  @override
  State<ProfileReevaluationCountdown> createState() =>
      _ProfileReevaluationCountdownState();
}

class _ProfileReevaluationCountdownState
    extends State<ProfileReevaluationCountdown> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final minutes = remaining.isNegative
        ? 0
        : (remaining.inSeconds / 60).ceil();
    final days = minutes ~/ 1440;
    final values = [days ~/ 30, days % 30, (minutes ~/ 60) % 24, minutes % 60];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SpacedColumn(
        gap: 8,
        children: [
          Text(
            minutes == 0
                ? _t(context, 'Ready for review')
                : '${_t(context, 'Time Remaining')}, ${DateFormat('d MMM', context.locale.toString()).format(widget.deadline)}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
          if (minutes > 0)
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.blueLight),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.blueStrong10,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            values[i].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1.25,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t(
                            context,
                            ['Months', 'Days', 'Hours', 'Minutes'][i],
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

String _t(BuildContext context, String value) =>
    ('talent_${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '')}')
        .tr(context: context);
