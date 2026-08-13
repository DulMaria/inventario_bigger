import 'package:flutter/material.dart';

import '../controller/obra_controller.dart';
import 'seleccionar_ubicacion_view.dart';

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

  double? _latitud;
  double? _longitud;

  Future<void> _seleccionarEnMapa() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SeleccionarUbicacionView(),
      ),
    );

    if (resultado == null || !mounted) return;

    setState(() {
      _direccionController.text =
          resultado['direccion'] ?? '';

      _latitud = resultado['latitud'];
      _longitud = resultado['longitud'];
    });
  }

  Future<void> _crearObra() async {
    final nombre = _nombreController.text.trim();
    final direccion = _direccionController.text.trim();

    // Validar nombre vacío
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre de la obra'),
        ),
      );
      return;
    }

    // Validar que no sean solamente espacios
    if (nombre.replaceAll(' ', '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la obra no es válido'),
        ),
      );
      return;
    }

    // Máximo de caracteres
    if (nombre.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre de la obra no puede superar los 100 caracteres',
          ),
        ),
      );
      return;
    }

    // Dirección obligatoria
    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese o seleccione la dirección de la obra'),
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      // Comprobar si ya existe una obra con ese nombre
      final existe = await _obraController.existeObraConNombre(
        nombre,
      );

      if (existe) {
        if (!mounted) return;

        setState(() {
          _cargando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ya existe una obra con el nombre "$nombre"',
            ),
          ),
        );

        return;
      }

      // Crear obra
      await _obraController.crearObra(
        nombre: nombre,
        direccion: direccion,
        latitud: _latitud,
        longitud: _longitud,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra creada correctamente'),
        ),
      );

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Nombre de la obra',
                hintText: 'Ej. Edificio Central',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _direccionController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                hintText: 'Ej. Av. Arce, La Paz',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // BOTÓN DEL MAPA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cargando
                    ? null
                    : _seleccionarEnMapa,
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'Seleccionar dirección en el mapa',
                ),
              ),
            ),

            // Mostrar coordenadas solo como referencia
            if (_latitud != null && _longitud != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ubicación seleccionada',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

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