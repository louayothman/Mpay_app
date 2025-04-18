import 'package:flutter_test/flutter_test.dart';
import 'package:mpay_app/widgets/motion_effects.dart';
import 'package:flutter/material.dart';

void main() {
  group('اختبارات الرسوم المتحركة', () {
    testWidgets('اختبار FadeInAnimation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // التحقق من وجود الحاوية
      expect(find.byType(Container), findsOneWidget);
      
      // انتظار انتهاء الرسوم المتحركة
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('اختبار SlideAnimation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              direction: SlideDirection.fromBottom,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      // التحقق من وجود الحاوية
      expect(find.byType(Container), findsOneWidget);
      
      // انتظار انتهاء الرسوم المتحركة
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('اختبار ScaleAnimation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScaleAnimation(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      // التحقق من وجود الحاوية
      expect(find.byType(Container), findsOneWidget);
      
      // انتظار انتهاء الرسوم المتحركة
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
