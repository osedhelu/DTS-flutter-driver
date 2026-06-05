import 'package:dts_driver/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App conductor arranca', (tester) async {
    await tester.pumpWidget(const DtsDriverApp());
    expect(find.text('DTS Conductor — iniciar con /fase-4'), findsOneWidget);
  });
}
