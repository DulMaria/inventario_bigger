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

  // ============================================================
  // SELECCIONAR UBICACIÓN EN EL MAPA
  // ============================================================

  Future<void> _seleccionarEnMapa() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarUbicacionView()),
    );

    if (resultado == null || !mounted) return;

    setState(() {
      _direccionController.text = resultado['direccion']?.toString() ?? '';

      _latitud = resultado['latitud'] != null
          ? (resultado['latitud'] as num).toDouble()
          : null;

      _longitud = resultado['longitud'] != null
          ? (resultado['longitud'] as num).toDouble()
          : null;
    });
  }

  // ============================================================
  // CREAR OBRA
  // ============================================================

  Future<void> _crearObra() async {
    final nombre = _nombreController.text.trim();
    final direccion = _direccionController.text.trim();

    // ------------------------------------------------------------
    // VALIDAR NOMBRE
    // ------------------------------------------------------------

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el nombre de la obra')),
      );
      return;
    }

    if (nombre.replaceAll(' ', '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la obra no es válido')),
      );
      return;
    }

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

    // ------------------------------------------------------------
    // VALIDAR DIRECCIÓN
    // ------------------------------------------------------------

    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese o seleccione la dirección de la obra'),
        ),
      );
      return;
    }

    // ------------------------------------------------------------
    // VALIDAR UBICACIÓN
    // ------------------------------------------------------------

    if (_latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione la ubicación de la obra en el mapa'),
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      // ----------------------------------------------------------
      // COMPROBAR NOMBRE DUPLICADO
      // ----------------------------------------------------------

      final existe = await _obraController.existeObraConNombre(nombre);

      if (existe) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya existe una obra con el nombre "$nombre"')),
        );

        return;
      }

      // ----------------------------------------------------------
      // CREAR OBRA
      // ----------------------------------------------------------

      await _obraController.crearObra(
        nombre: nombre,
        direccion: direccion,
        latitud: _latitud,
        longitud: _longitud,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obra creada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear la obra: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear obra')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ----------------------------------------------------
            // NOMBRE
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // DIRECCIÓN
            // ----------------------------------------------------
            TextField(
              controller: _direccionController,
              maxLength: 200,
              maxLines: 2,

              onChanged: (_) {
                /*
                 * Si el gerente modifica manualmente la dirección,
                 * dejamos de considerar válida la ubicación anterior.
                 */
                if (_latitud != null || _longitud != null) {
                  setState(() {
                    _latitud = null;
                    _longitud = null;
                  });
                }
              },

              decoration: const InputDecoration(
                labelText: 'Dirección',
                hintText: 'Seleccione la dirección en el mapa',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // MAPA
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: _cargando ? null : _seleccionarEnMapa,

                icon: const Icon(Icons.location_on),

                label: Text(
                  _latitud != null && _longitud != null
                      ? 'Cambiar ubicación en el mapa'
                      : 'Seleccionar ubicación en el mapa',
                ),
              ),
            ),

            // ----------------------------------------------------
            // UBICACIÓN SELECCIONADA
            // ----------------------------------------------------
            if (_latitud != null && _longitud != null) ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.check_circle, size: 20),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Ubicación seleccionada correctamente',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ----------------------------------------------------
            // BOTÓN CREAR
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _cargando ? null : _crearObra,

                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,

                        child: CircularProgressIndicator(strokeWidth: 2),
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
