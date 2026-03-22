import 'package:flutter_test/flutter_test.dart';

import 'package:sbg_profesores/main.dart';

void main() {
  testWidgets('MyApp renderiza correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo deseas ingresar?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
