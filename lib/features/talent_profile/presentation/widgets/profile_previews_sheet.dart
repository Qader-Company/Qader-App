import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../profile_copy.dart';

Future<void> showProfilePreviews(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tc(context, 'Profile previews'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            for (final item in [
              (
                'Evaluation report',
                AppRouter.profileReport,
                Icons.assessment_outlined,
              ),
              (
                'Rejected profile',
                '${AppRouter.talentProfile}?status=rejected',
                Icons.person_off_outlined,
              ),
              (
                'Restricted profile',
                '${AppRouter.talentProfile}?status=restricted',
                Icons.lock_outline,
              ),
            ])
              ListTile(
                leading: Icon(item.$3),
                title: Text(tc(context, item.$1)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(item.$2);
                },
              ),
          ],
        ),
      ),
    );
