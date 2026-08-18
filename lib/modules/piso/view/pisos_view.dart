import 'package:flutter/material.dart';

import '../../../models/obra_model.dart';
import '../../../models/piso_model.dart';
import '../controller/piso_controller.dart';
import 'crear_piso_view.dart';
import 'editar_piso_view.dart';

class PisosView extends StatefulWidget {
  final ObraModel obra;

  const PisosView({super.key, required this.obra});

  @override
  State<PisosView> createState() => _PisosViewState();
}

class _PisosViewState extends State<PisosView> {
  final PisoController _pisoController = PisoController();

  List<PisoModel> _pisos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPisos();
  }

  Future<void> _cargarPisos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final pisos = await _pisoController.obtenerPisos(widget.obra.idObra);

      if (!mounted) return;

      setState(() {
        _pisos = pisos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar los pisos: $e')));
    }
  }

  Future<void> _irACrearPiso() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPisoView(idObra: widget.obra.idObra),
      ),
    );

    if (resultado == true) {
      _cargarPisos();
    }
  }

  Future<void> _irAEditarPiso(PisoModel piso) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarPisoView(piso: piso)),
    );

    if (resultado == true) {
      _cargarPisos();
    }
  }

  String _textoTipo(String tipo) {
    switch (tipo) {
      case 'NORMAL':
        return 'Piso';
      case 'SOTANO':
        return 'Sótano';
      case 'TERRAZA':
        return 'Terraza';
      default:
        return tipo;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'NO INICIADO':
        return 'No iniciado';
      case 'OBRA BRUTA':
        return 'Obra bruta';
      case 'OBRA FINA':
        return 'Obra fina';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.obra.nombre)),
      floatingActionButton: FloatingActionButton(
        onPressed: _irACrearPiso,
        child: const Icon(Icons.add),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pisos.isEmpty
          ? const Center(
              child: Text('Esta obra todavía no tiene pisos registrados'),
            )
          : RefreshIndicator(
              onRefresh: _cargarPisos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pisos.length,
                itemBuilder: (context, index) {
                  final piso = _pisos[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.layers),
                      title: Text(piso.nombre ?? 'Sin nombre'),
                      subtitle: Text(
                        '${_textoTipo(piso.tipoPiso)} '
                        '${piso.numeroPiso}\n'
                        'Estado: ${_textoEstado(piso.estadoObra)}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _irAEditarPiso(piso);
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
