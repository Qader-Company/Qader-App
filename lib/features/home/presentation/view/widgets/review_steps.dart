import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';

class ReviewSteps extends StatelessWidget {
  const ReviewSteps({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: 46,
      child: Stack(
        children: [
          PositionedDirectional(
            start: constraints.maxWidth * .148,
            end: constraints.maxWidth * .137,
            top: 34,
            child: const Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: QaderAsset('step_line_active'),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: QaderAsset('step_line_pending'),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final key in ['under_review', 'interviews', 'accepted'])
                Flexible(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          key.tr(context: context),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: key == 'under_review'
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: key == 'under_review'
                                ? QaderDesign.primary
                                : const Color(0xFF737373),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      QaderAsset(
                        key == 'under_review' ? 'step_active' : 'step_pending',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
