import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final opcion in seedColorOptions)
                    _SeedColorSwatch(
                      opcion: opcion,
                      seleccionado: settings.seedColor.toARGB32() == opcion.color.toARGB32(),
                      onTap: () => settings.setSeedColor(opcion.color),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Modo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode_outlined)),
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.smartphone_outlined)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeedColorSwatch extends StatelessWidget {
  final SeedColorOption opcion;
  final bool seleccionado;
  final VoidCallback onTap;

  const _SeedColorSwatch({required this.opcion, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: opcion.color,
              shape: BoxShape.circle,
              border: seleccionado
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                  : null,
            ),
            child: seleccionado ? const Icon(Icons.check, color: Colors.white) : null,
          ),
          const SizedBox(height: 6),
          Text(opcion.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
