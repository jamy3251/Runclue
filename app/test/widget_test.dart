import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:runclue/config/theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Dark theme applies correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: Text('RunClue')),
      ),
    );
    expect(find.text('RunClue'), findsOneWidget);

    final theme = Theme.of(tester.element(find.text('RunClue')));
    expect(theme.brightness, Brightness.dark);
  });

  testWidgets('Light theme applies correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('RunClue')),
      ),
    );
    expect(find.text('RunClue'), findsOneWidget);
  });

  test('AppColors constants are correct', () {
    expect(AppColors.brandYellow, const Color(0xFFFACC15));
    expect(AppColors.brandBlue, const Color(0xFF38BDF8));
    expect(AppColors.bgBase, const Color(0xFF111115));
  });

  test('AppShadows and AppGradients exist', () {
    expect(AppShadows.card, isNotNull);
    expect(AppShadows.ctaYellow, isNotNull);
    expect(AppGradients.ctaYellow, isNotNull);
    expect(AppGradients.progress, isNotNull);
  });

  test('AppSpacing constants are correct', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.lg, 16);
    expect(AppSpacing.xxl, 32);
  });

  test('AppDurations are reasonable', () {
    expect(AppDurations.fast.inMilliseconds, 200);
    expect(AppDurations.normal.inMilliseconds, 300);
    expect(AppDurations.celebration.inMilliseconds, 3000);
  });
}
