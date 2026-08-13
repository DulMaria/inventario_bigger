import 'package:flutter/material.dart';

import '../controller/obra_controller.dart';
import '../../../models/obra_model.dart';
import 'crear_obra_view.dart';
import 'editar_obra_view.dart';
import '../../piso/view/pisos_view.dart';

class ObrasView extends StatefulWidget {
  const ObrasView({super.key});

  @override
  State<ObrasView> createState() => _ObrasViewState();
}

class _ObrasViewState extends State<ObrasView> {
  final ObraController _obraController = ObraController();

  List<ObraModel> _obras = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  Future<void> _cargarObras() async {
    setState(() {
      _cargando = true;
    });

    try {
      final obras = await _obraController.obtenerObras();

      if (!mounted) return;

      setState(() {
        _obras = obras;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las obras: $e'),
        ),
      );
    }
  }

  // Ir a crear una obra
  Future<void> _irACrearObra() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CrearObraView(),
      ),
    );

    if (resultado == true) {
      _cargarObras();
    }
  }

  // Ir a editar una obra
  Future<void> _irAEditarObra(ObraModel obra) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarObraView(
          obra: obra,
        ),
      ),
    );

    if (resultado == true) {
      _cargarObras();
    }
  }

  // Ir a los pisos de una obra
  Future<void> _irAPisos(ObraModel obra) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PisosView(
          obra: obra,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras'),
      ),

      // Crear obra
      floatingActionButton: FloatingActionButton(
        onPressed: _irACrearObra,
        child: const Icon(Icons.add),
      ),

      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _obras.isEmpty
              ? const Center(
                  child: Text('No hay obras registradas'),
                )
              : RefreshIndicator(
                  onRefresh: _cargarObras,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _obras.length,
                    itemBuilder: (context, index) {
                      final obra = _obras[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.business,
                          ),

                          title: Text(
                            obra.nombre,
                          ),

                          subtitle: Text(
                            obra.direccion ?? 'Sin dirección',
                          ),

                          // Tocar la obra
                          // abre sus pisos
                          onTap: () {
                            _irAPisos(obra);
                          },

                          // Editar obra
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                            ),
                            onPressed: () {
                              _irAEditarObra(obra);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}