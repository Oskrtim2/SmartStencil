import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/core/errors/fatal_error_view.dart';

void main() {
  testWidgets('shows a friendly fatal error message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FatalErrorView()));

    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.textContaining('Reinicia la app'), findsOneWidget);
  });
}
