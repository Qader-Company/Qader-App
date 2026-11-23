import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/widgets/app_toast.dart';

void main() {
  testWidgets('one toast at a time, styled by its type', (tester) async {
    tester.view.physicalSize = const Size(390, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final key = GlobalKey();
    Future<void> capture(String name) => tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/design_review/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    late BuildContext context;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    showAppToast(context, 'Saved', type: ToastType.success);
    await tester.pumpAndSettle();
    await capture('toast_success');
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-toast-success')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // A new message replaces the old one.
    showAppToast(context, 'Failed', type: ToastType.error);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    await capture('toast_error');

    showAppToast(context, 'Coming soon');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-toast-info')), findsOneWidget);
    await capture('toast_info');
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a messenger nothing happens', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox();
        },
      ),
    );
    showAppToast(context, 'Ignored');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
