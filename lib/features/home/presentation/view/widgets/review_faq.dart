import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';

class ReviewFaq extends StatefulWidget {
  const ReviewFaq({super.key});
  @override
  State<ReviewFaq> createState() => _ReviewFaqState();
}

class _ReviewFaqState extends State<ReviewFaq> {
  final Set<int> _expanded = {0};
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'faq_title'.tr(context: context),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _expanded.contains(i),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      if (!_expanded.add(i)) _expanded.remove(i);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'faq_q$i'.tr(context: context),
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: _expanded.contains(i)
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          QaderAsset(
                            _expanded.contains(i)
                                ? 'chevron_up'
                                : 'chevron_down',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_expanded.contains(i))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Text(
                      'faq_a$i'.tr(context: context),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: QaderDesign.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
