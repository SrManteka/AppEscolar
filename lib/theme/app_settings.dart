import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

const _claveSeedColor = 'seed_color';
const _claveThemeMode = 'theme_mode';

/// Preferencias de apariencia (color semilla + modo claro/oscuro/sistema).
/// Vive en shared_preferences, no en la base de datos SQLite del modelo de
/// datos -- es configuración de la app, no un dato escolar (ver diseno.md).
class AppSettings extends ChangeNotifier {
  Color seedColor;
  ThemeMode themeMode;

  AppSettings({this.seedColor = defaultSeedColor, this.themeMode = ThemeMode.system});

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorGuardado = prefs.getInt(_claveSeedColor);
    final modoGuardado = prefs.getInt(_claveThemeMode);
    return AppSettings(
      seedColor: colorGuardado != null ? Color(colorGuardado) : defaultSeedColor,
      themeMode: modoGuardado != null ? ThemeMode.values[modoGuardado] : ThemeMode.system,
    );
  }

  Future<void> setSeedColor(Color color) async {
    seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveSeedColor, color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode modo) async {
    themeMode = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveThemeMode, modo.index);
  }
}
