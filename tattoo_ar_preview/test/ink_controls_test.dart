import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/core/theme/app_theme.dart';
import 'package:tattoo_ar_preview/features/editor/presentation/widgets/ink_controls.dart';

void main() {
  Future<void> pumpControls(
    WidgetTester tester, {
    required ValueNotifier<double> opacity,
    required bool hasDesign,
    bool isPicking = false,
    bool isCapturing = false,
    bool canCapture = false,
    required VoidCallback onPick,
    required VoidCallback onCapture,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: InkControls(
                opacity: opacity,
                hasDesign: hasDesign,
                isPicking: isPicking,
                isCapturing: isCapturing,
                canCapture: canCapture,
                onOpacityChanged: (double value) => opacity.value = value,
                onPick: onPick,
                onCapture: onCapture,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'disables the slider and shows a neutral value without a design',
    (WidgetTester tester) async {
      final ValueNotifier<double> opacity = ValueNotifier<double>(0.82);
      bool picked = false;

      await pumpControls(
        tester,
        opacity: opacity,
        hasDesign: false,
        onPick: () => picked = true,
        onCapture: () {},
      );

      expect(find.text('—'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
      expect(find.byTooltip('Importa un diseño para capturar'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pump();

      expect(picked, isTrue);
      opacity.dispose();
    },
  );

  testWidgets('updates opacity and fires pick and capture callbacks', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<double> opacity = ValueNotifier<double>(0.5);
    bool picked = false;
    bool captured = false;

    await pumpControls(
      tester,
      opacity: opacity,
      hasDesign: true,
      canCapture: true,
      onPick: () => picked = true,
      onCapture: () => captured = true,
    );

    expect(find.text('50%'), findsOneWidget);
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNotNull);
    slider.onChanged!(0.25);
    await tester.pump();
    expect(find.text('25%'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pump();
    expect(picked, isTrue);

    await tester.tap(find.byTooltip('Capturar y compartir'));
    await tester.pump();
    expect(captured, isTrue);

    opacity.dispose();
  });

  testWidgets('shows a progress indicator while importing', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<double> opacity = ValueNotifier<double>(0.82);

    await pumpControls(
      tester,
      opacity: opacity,
      hasDesign: false,
      isPicking: true,
      onPick: () {},
      onCapture: () {},
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    opacity.dispose();
  });
}
