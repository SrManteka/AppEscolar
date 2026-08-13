import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../fotos/foto_storage.dart';
import '../../fotos/widgets/foto_source_sheet.dart';
import '../fotos/fotos_screen.dart';
import '../notas/notas_screen.dart';
import '../notas/widgets/nota_form_sheet.dart';
import '../proyectos/proyectos_screen.dart';
import '../proyectos/widgets/proyecto_form_sheet.dart';
import '../tareas/tareas_screen.dart';
import '../tareas/widgets/tarea_form_sheet.dart';

/// Pantalla de una materia: Notas/Tareas/Proyectos/Fotos como TabBar
/// estandar de Material, no navegacion custom (ver docs/diseno.md,
/// "Patrones de pantalla").
class MateriaScreen extends StatefulWidget {
  final AppDatabase db;
  final Materia materia;

  const MateriaScreen({super.key, required this.db, required this.materia});

  @override
  State<MateriaScreen> createState() => _MateriaScreenState();
}

class _MateriaScreenState extends State<MateriaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _agregarFoto(BuildContext context) async {
    final fuente = await elegirFuenteFoto(context);
    if (fuente == null) return;
    final ruta = await FotoStorage.instance.elegirYGuardar(fuente);
    if (ruta == null) return;
    await widget.db.into(widget.db.fotos).insert(
      FotosCompanion.insert(materiaId: widget.materia.id, rutaArchivo: ruta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materia.nombre),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Notas'), Tab(text: 'Tareas'), Tab(text: 'Proyectos'), Tab(text: 'Fotos')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotasScreen(db: widget.db, materia: widget.materia),
          TareasScreen(db: widget.db, materia: widget.materia),
          ProyectosScreen(db: widget.db, materia: widget.materia),
          FotosScreen(db: widget.db, materia: widget.materia),
        ],
      ),
      floatingActionButton: switch (_tabController.index) {
        0 => FloatingActionButton(
            onPressed: () =>
                mostrarFormularioNota(context: context, db: widget.db, materiaId: widget.materia.id),
            child: const Icon(Icons.add),
          ),
        1 => FloatingActionButton(
            onPressed: () =>
                mostrarFormularioTarea(context: context, db: widget.db, materiaId: widget.materia.id),
            child: const Icon(Icons.add),
          ),
        2 => FloatingActionButton(
            onPressed: () => mostrarFormularioProyecto(
              context: context,
              db: widget.db,
              materiaId: widget.materia.id,
            ),
            child: const Icon(Icons.add),
          ),
        _ => FloatingActionButton(
            onPressed: () => _agregarFoto(context),
            child: const Icon(Icons.add_a_photo_outlined),
          ),
      },
    );
  }
}
