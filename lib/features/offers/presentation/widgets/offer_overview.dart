import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';

/// White rounded card with a light border, used by every details section.
class OfferPanel extends StatelessWidget {
  const OfferPanel({super.key, required this.children, this.title});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],
        ...children,
      ],
    ),
  );
}

/// "Label: **value**".
class OfferLabeledValue extends StatelessWidget {
  const OfferLabeledValue(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text.rich(
      TextSpan(
        text: '$label: ',
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: AppColors.neutral700,
      ),
    ),
  );
}

class OfferCompanyCard extends StatelessWidget {
  const OfferCompanyCard({super.key, required this.company, this.onWebsite});
  final OfferCompany company;
  final VoidCallback? onWebsite;
  @override
  Widget build(BuildContext context) => OfferPanel(
    children: [
      Row(
        children: [
          CompanyLogo(name: company.name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              company.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (company.industry.isNotEmpty)
        OfferLabeledValue(ot(context, 'industry'), company.industry),
      if (company.location.isNotEmpty)
        OfferLabeledValue(ot(context, 'location'), company.location),
      if (company.website case final website?)
        InkWell(
          onTap: onWebsite,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              website.replaceFirst(RegExp(r'^https?://'), ''),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.blueStrong,
              ),
            ),
          ),
        ),
    ],
  );
}

/// Offer → Interview → Accepted, with the current step highlighted and a
/// failed step in red.
class OfferHiringProgress extends StatelessWidget {
  const OfferHiringProgress({super.key, required this.stage});
  final OfferStage stage;
  @override
  Widget build(BuildContext context) {
    final current = stage.progressStep;
    final labels = [
      ot(context, 'step_offer'),
      ot(context, 'step_interview'),
      ot(context, 'step_accepted'),
    ];
    _StepState state(int step) => step < current
        ? _StepState.done
        : step > current
        ? _StepState.pending
        : stage.failed
        ? _StepState.failed
        : stage == OfferStage.contracted
        ? _StepState.done
        : _StepState.current;
    return OfferPanel(
      title: ot(context, 'hiring_progress'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: state(i - 1) == _StepState.failed
                          ? AppColors.red300
                          : AppColors.neutral200,
                    ),
                  ),
                ),
              _Step(label: labels[i], state: state(i)),
            ],
          ],
        ),
      ],
    );
  }
}

enum _StepState { done, current, failed, pending }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state});
  final String label;
  final _StepState state;
  @override
  Widget build(BuildContext context) {
    final (halo, dot, text) = switch (state) {
      _StepState.done => (
        AppColors.blueStrong,
        AppColors.blueStrong,
        AppColors.blueStrong,
      ),
      _StepState.current => (
        AppColors.blueSoft,
        AppColors.blueStrong,
        AppColors.blueStrong,
      ),
      _StepState.failed => (
        AppColors.red100,
        AppColors.red600,
        AppColors.red600,
      ),
      _StepState.pending => (
        AppColors.neutral200,
        AppColors.neutral400,
        AppColors.neutral500,
      ),
    };
    return Semantics(
      selected: state == _StepState.current,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
            child: state == _StepState.done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  state == _StepState.current || state == _StepState.failed
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
