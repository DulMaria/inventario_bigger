import 'package:flutter/material.dart';

import '../controller/obra_controller.dart';

class CrearObraView extends StatefulWidget {
  const CrearObraView({super.key});

  @override
  State<CrearObraView> createState() => _CrearObraViewState();
}

class _CrearObraViewState extends State<CrearObraView> {
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();

  final ObraController _obraController = ObraController();

  bool _cargando = false;

  Future<void> _crearObra() async {
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
      await _obraController.crearObra(
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra creada correctamente'),
        ),
      );

      // Regresa a la lista indicando que se creó una obra.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la obra: $e'),
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
        title: const Text('Crear obra'),
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
                onPressed: _cargando ? null : _crearObra,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Crear obra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}