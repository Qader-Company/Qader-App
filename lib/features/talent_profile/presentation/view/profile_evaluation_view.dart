import 'package:flutter/material.dart';
import '../../domain/profile_evaluation.dart';
import '../profile_copy.dart';
import '../widgets/profile_components.dart';
import '../widgets/evaluation_report_widgets.dart';

class ProfileEvaluationView extends StatefulWidget {
  const ProfileEvaluationView({super.key});
  @override
  State<ProfileEvaluationView> createState() => _ProfileEvaluationViewState();
}

class _ProfileEvaluationViewState extends State<ProfileEvaluationView> {
  final _open = <int>{0};
  bool _salaryOpen = false;
  @override
  Widget build(BuildContext context) => TalentProfileScaffold(
    child: ProfileStack(
      gap: 24,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ProfileStack(
            gap: 12,
            children: [
              Center(
                child: Text(
                  tc(context, 'Expected Salary Recommendations'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Text(
                '20k–30k',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              Text(
                tc(context, 'Based on your skills and experience'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Align(
                    alignment: const Alignment(-.5, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.white,
                      child: Text(
                        tc(context, 'Your range'),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFFBBF24),
                          Color(0xFF22C55E),
                          Color(0xFF1D52E5),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0k', style: TextStyle(fontSize: 10)),
                      Text('120k', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _salaryOpen = !_salaryOpen),
                child: Text(
                  tc(
                    context,
                    _salaryOpen
                        ? 'Hide Recommendations'
                        : 'See Recommendations (30%)',
                  ),
                  style: const TextStyle(fontSize: 12, color: profileBlue),
                ),
              ),
              if (_salaryOpen)
                Text(
                  tc(
                    context,
                    'Improve your profile with measurable achievements, current skills and clear project examples to strengthen your market position.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF737373),
                  ),
                ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => setState(() {
              if (_open.isEmpty) {
                _open.addAll([0, 1]);
              } else {
                _open.clear();
              }
            }),
            child: Text(
              tc(context, _open.isEmpty ? 'Expand all' : 'Collapse all'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        ProfileStack(
          gap: 6,
          children: [
            const ProfileHeading('Interview Evaluations'),
            Text(
              tc(context, 'Detailed evaluation of your skills and experience'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
            ),
          ],
        ),
        EvaluationAccordion(
          title: 'Profile Review',
          open: _open.contains(0),
          onTap: () => _toggle(0),
          children: [
            Text(
              tc(context, 'Evaluation Details'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            for (final metric in ProfileEvaluation.metrics)
              EvaluationMetricCard(metric: metric),
            for (final report in ProfileEvaluation.reports)
              EvaluationTextCard(title: report.$1, text: report.$2),
            const ProfileHeading('Personalized Expert Tips & Guidance'),
            for (var i = 0; i < ProfileEvaluation.tips.length; i++)
              ExpertTipCard(text: ProfileEvaluation.tips[i], index: i),
          ],
        ),
        EvaluationAccordion(
          title: 'Overall HR Interview',
          open: _open.contains(1),
          onTap: () => _toggle(1),
          children: [
            EvaluationTextCard(
              title: 'HR Report',
              text: ProfileEvaluation.reports.first.$2,
            ),
            for (final metric in ProfileEvaluation.metrics.take(2))
              EvaluationMetricCard(metric: metric),
          ],
        ),
      ],
    ),
  );
  void _toggle(int id) => setState(() {
    if (!_open.remove(id)) _open.add(id);
  });
}
