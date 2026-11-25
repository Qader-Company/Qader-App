import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/features/notifications/domain/entities/app_notification.dart';
import 'package:qader/features/notifications/presentation/widgets/notification_tile.dart';

void main() {
  testWidgets('English text in the Arabic UI keeps its own direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NotificationTile(
              notification: const AppNotification(
                id: '1',
                type: 'fcm_test',
                title: 'Qader',
                body: 'FCM connection is working.',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    TextDirection? direction(String text) =>
        tester.widget<Text>(find.text(text)).textDirection;
    expect(direction('FCM connection is working.'), TextDirection.ltr);
    expect(direction('Qader'), TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });
}
