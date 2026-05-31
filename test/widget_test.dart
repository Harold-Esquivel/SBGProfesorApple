import 'package:flutter_test/flutter_test.dart';

import 'package:sbg_profesores/main.dart';
import 'package:sbg_profesores/theme/app_theme.dart';

void main() {
  testWidgets('MyApp renderiza correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(themeController: AppThemeController(isDarkMode: false)),
    );
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo deseas ingresar?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
