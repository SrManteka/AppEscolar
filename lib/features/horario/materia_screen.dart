import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../notas/notas_screen.dart';
import '../notas/widgets/nota_form_sheet.dart';
import '../tareas/tareas_screen.dart';
import '../tareas/widgets/tarea_form_sheet.dart';

/// Pantalla de una materia: Notas y Tareas como TabBar estandar de Material,
/// no navegacion custom (ver docs/diseno.md, "Patrones de pantalla").
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
    _tabController = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materia.nombre),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Notas'), Tab(text: 'Tareas')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotasScreen(db: widget.db, materia: widget.materia),
          TareasScreen(db: widget.db, materia: widget.materia),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () =>
                  mostrarFormularioNota(context: context, db: widget.db, materiaId: widget.materia.id),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () =>
                  mostrarFormularioTarea(context: context, db: widget.db, materiaId: widget.materia.id),
              child: const Icon(Icons.add),
            ),
    );
  }
}
