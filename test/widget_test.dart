import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_escolar/database/database.dart';
import 'package:app_escolar/main.dart';
import 'package:app_escolar/theme/app_settings.dart';

void main() {
  testWidgets('La pantalla de Horario carga sin clases', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(AppEscolar(db: db, settings: AppSettings()));
    await tester.pumpAndSettle();

    expect(find.text('Horario'), findsOneWidget);
    expect(find.text('Todavía no tienes clases registradas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
