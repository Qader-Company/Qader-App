import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/widgets/skeleton.dart';
import 'package:qader/features/auth/presentation/view/widgets/auth_skeletons.dart';
import 'package:qader/features/home/presentation/view/widgets/home_skeleton.dart';
import 'package:qader/features/offers/presentation/widgets/offer_card_skeleton.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_form_skeleton.dart';
import 'package:qader/features/talent_profile/presentation/widgets/profile_skeleton.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = false,
    GlobalKey? captureKey,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: RepaintBoundary(
              key: captureKey,
              child: ColoredBox(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shimmer keeps animating until the skeleton is removed', (
    tester,
  ) async {
    await pump(tester, const ProfileSkeleton());
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion shows still boxes', (tester) async {
    await pump(tester, const OfferListSkeleton(), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(SkeletonBox), findsWidgets);
  });

  testWidgets('a box without a shimmer still paints', (tester) async {
    await pump(tester, const SkeletonBox(width: 40, height: 10));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every skeleton lays out on a narrow screen', (tester) async {
    final captureKey = GlobalKey();
    final skeletons = {
      'skeleton_profile': const ProfileSkeleton(),
      'skeleton_offers': const OfferListSkeleton(),
      'skeleton_home': const HomeSkeleton(),
      'skeleton_profile_form': const ProfileFormSkeleton(),
      'skeleton_professional_fields': const ProfessionalFieldSkeleton(),
      'skeleton_account': const AccountSkeleton(),
      'skeleton_email_verification': const OtpFormSkeleton(),
    };
    for (final MapEntry(key: name, value: skeleton) in skeletons.entries) {
      await pump(
        tester,
        skeleton,
        disableAnimations: true,
        captureKey: captureKey,
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/design_review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    tester.view.physicalSize = const Size(320, 1400);
    for (final skeleton in skeletons.values) {
      await pump(tester, skeleton, disableAnimations: true);
      expect(tester.takeException(), isNull);
    }
  });
}
