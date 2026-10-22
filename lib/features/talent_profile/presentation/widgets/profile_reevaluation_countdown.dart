import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../profile_copy.dart';
import 'profile_components.dart';

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
        color: const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ProfileStack(
        gap: 8,
        children: [
          Text(
            minutes == 0
                ? tc(context, 'Ready for review')
                : '${tc(context, 'Time Remaining')}, ${DateFormat(
                        'd MMM',
                        context.locale.toString(),
                      ).format(widget.deadline)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF525252)),
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
                            border: Border.all(color: const Color(0xFFB8D0FF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A1D52E5),
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
                              color: Color(0xFF346AE8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tc(
                            context,
                            ['Months', 'Days', 'Hours', 'Minutes'][i],
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF737373),
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
