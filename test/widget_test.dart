import 'package:dts_driver/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App conductor arranca', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DtsDriverApp()));
    await tester.pumpAndSettle();

    expect(find.text('Conductor — Iniciar sesión'), findsOneWidget);
  });
}
