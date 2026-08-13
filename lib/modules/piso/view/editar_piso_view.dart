import 'package:flutter/material.dart';

import '../../../models/piso_model.dart';
import '../controller/piso_controller.dart';

class EditarPisoView extends StatefulWidget {
  final PisoModel piso;

  const EditarPisoView({
    super.key,
    required this.piso,
  });

  @override
  State<EditarPisoView> createState() => _EditarPisoViewState();
}

class _EditarPisoViewState extends State<EditarPisoView> {
  late final TextEditingController _nombreController;

  final PisoController _pisoController = PisoController();

  late String _estadoSeleccionado;

  bool _cargando = false;

  final List<String> _estados = [
    'NO INICIADO',
    'OBRA BRUTA',
    'OBRA FINA',
  ];

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.piso.nombre,
    );

    _estadoSeleccionado = widget.piso.estadoObra;
  }

  Future<void> _editarPiso() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre del piso'),
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      await _pisoController.editarPiso(
        idPiso: widget.piso.idPiso,
        nombre: nombre,
        estadoObra: _estadoSeleccionado,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el piso: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar piso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del piso',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Estado de la obra',
                border: OutlineInputBorder(),
              ),
              items: _estados.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(estado),
                );
              }).toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    _estadoSeleccionado = valor;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _editarPiso,
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}