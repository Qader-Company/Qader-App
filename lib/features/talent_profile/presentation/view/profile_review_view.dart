import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../profile_copy.dart';
import '../widgets/profile_components.dart';

class ProfileReviewView extends StatelessWidget {
  const ProfileReviewView({super.key});
  @override
  Widget build(BuildContext context) => TalentProfileScaffold(
    child: ProfileStack(
      gap: 24,
      children: [
        ProfileStack(
          gap: 12,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tc(context, 'Premium Service'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: profileBlue,
                  ),
                ),
              ),
            ),
            Text(
              tc(context, 'Get an Expert Review of Your Profile'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            Text(
              tc(
                context,
                "Wondering why you're not getting enough interviews? Let one of our experts review your entire profile and provide you with a detailed report along with personalized tips to improve your ranking and market fit.",
              ),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF737373),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ProfileStack(
            gap: 12,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tc(context, r'$10 One-Time Payment'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: profileBlue,
                  ),
                ),
              ),
              Text(
                tc(context, 'Start Your Personalized Review Now'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              DefaultButton.compact(
                text: tc(context, 'Buy the Review Now'),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () => profileNotice(
                  context,
                  'Review purchase',
                  'Purchasing is not connected yet and no payment has been taken',
                ),
              ),
              Text(
                tc(context, '500+ professionals successfully reviewed'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
              ),
              for (final text in [
                'Comprehensive review by a human hiring expert',
                'Detailed report sent to your account within 48 hours',
                'Personalized recommendations to boost your acceptance rate by 60%',
                '14-day money-back guarantee',
              ])
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tc(context, text),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        for (final feature in [
          (
            Icons.workspace_premium_outlined,
            'Profile Score & Ranking',
            'Get a precise score out of 100 for your profile and discover your true ranking compared to your peers and competitors in the same field.',
          ),
          (
            Icons.paid_outlined,
            'Expected Salary Recommendations',
            'Get personalized salary guidance based on your experience, skills, and market demand.',
          ),
          (
            Icons.query_stats,
            'Market Fit Analysis',
            'Analyze the market demand for your current skills and identify the most in-demand roles that match your experience.',
          ),
          (
            Icons.psychology_outlined,
            'Personalized Tips & Guidance',
            'Actionable steps you can apply immediately to make your resume stand out and look professional to hiring managers.',
          ),
        ])
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F8FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(feature.$1, color: profileBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileStack(
                  gap: 8,
                  children: [
                    Text(
                      tc(context, feature.$2),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      tc(context, feature.$3),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
