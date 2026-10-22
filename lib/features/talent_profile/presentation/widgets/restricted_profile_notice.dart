import 'package:flutter/material.dart';
import '../profile_copy.dart';

class RestrictedProfileNotice extends StatelessWidget {
  const RestrictedProfileNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFEF232A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${tc(context, 'Profile Restricted')}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: tc(
                    context,
                    'Your profile has been restricted and is currently unavailable for new job opportunities on Qader. If you believe this is a mistake or would like to request a review, please contact our support team.',
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 10,
              height: 1.6,
              color: Color(0xFF525252),
            ),
          ),
        ),
      ],
    ),
  );
}
