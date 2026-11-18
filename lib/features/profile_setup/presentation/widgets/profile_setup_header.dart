import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';

/// Logo with a direction-aware back button, at the top of profile setup.
class ProfileSetupHeader extends StatelessWidget {
  const ProfileSetupHeader({
    super.key,
    required this.showBack,
    required this.onBack,
  });
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const QaderLogo(),
        if (showBack)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.neutral50,
                ),
                tooltip: pc(context, 'Back'),
                onPressed: onBack,
                icon: Directionality.of(context) == TextDirection.rtl
                    ? const RotatedBox(
                        quarterTurns: 2,
                        child: QaderAsset(
                          'profile_back',
                          width: 7.5,
                          height: 13.5,
                        ),
                      )
                    : const QaderAsset(
                        'profile_back',
                        width: 7.5,
                        height: 13.5,
                      ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// "← Back to profile" under the Edit Profile header: the drawer page has
/// no back button of its own.
class ProfileEditBackLink extends StatelessWidget {
  const ProfileEditBackLink({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.neutral900,
      ),
      onPressed: onBack,
      icon: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_forward
            : Icons.arrow_back,
        size: 20,
      ),
      label: Text(
        pc(context, 'Back to profile'),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
