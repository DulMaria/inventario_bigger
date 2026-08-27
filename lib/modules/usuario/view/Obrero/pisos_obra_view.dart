import 'package:flutter/material.dart';

import '../../../../models/piso_model.dart';
import '../../../piso/controller/piso_controller.dart';

class PisosObraView extends StatefulWidget {
  final int idObra;

  const PisosObraView({super.key, required this.idObra});

  @override
  State<PisosObraView> createState() => _PisosObraViewState();
}

class _PisosObraViewState extends State<PisosObraView> {
  final PisoController _controller = PisoController();

  List<PisoModel> _pisos = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPisos();
  }

  Future<void> _cargarPisos() async {
    try {
      final pisos = await _controller.obtenerPisos(widget.idObra);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pisos de la obra')),

      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pisos.isEmpty
          ? const Center(child: Text('No hay pisos registrados en esta obra'))
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
                      leading: const CircleAvatar(child: Icon(Icons.apartment)),

                      title: Text(piso.nombre ?? 'Sin nombre'),

                      subtitle: Text(
                        piso.numeroPiso != null
                            ? 'Piso ${piso.numeroPiso}'
                            : piso.tipoPiso,
                      ),

                      trailing: Text(piso.estadoObra),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
