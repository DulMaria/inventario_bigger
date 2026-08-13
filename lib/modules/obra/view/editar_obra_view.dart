import 'package:flutter/material.dart';

import '../controller/obra_controller.dart';
import '../../../models/obra_model.dart';

class EditarObraView extends StatefulWidget {
  final ObraModel obra;

  const EditarObraView({
    super.key,
    required this.obra,
  });

  @override
  State<EditarObraView> createState() => _EditarObraViewState();
}

class _EditarObraViewState extends State<EditarObraView> {
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;

  final ObraController _obraController = ObraController();

  bool _cargando = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.obra.nombre,
    );

    _direccionController = TextEditingController(
      text: widget.obra.direccion,
    );
  }

  Future<void> _editarObra() async {
    if (_nombreController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      await _obraController.editarObra(
        idObra: widget.obra.idObra,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra actualizada correctamente'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al editar la obra: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar obra'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la obra',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _editarObra,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}