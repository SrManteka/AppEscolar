import 'package:flutter/material.dart';

import 'database/database.dart';
import 'features/horario/horario_screen.dart';

void main() {
  runApp(AppEscolar(db: AppDatabase()));
}

class AppEscolar extends StatelessWidget {
  final AppDatabase db;

  const AppEscolar({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppEscolar',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: HorarioScreen(db: db),
    );
  }
}
