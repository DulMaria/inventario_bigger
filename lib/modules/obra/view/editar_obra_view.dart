import 'package:flutter/material.dart';

import '../controller/obra_controller.dart';
import '../../../models/obra_model.dart';
import 'seleccionar_ubicacion_view.dart';

class EditarObraView extends StatefulWidget {
  final ObraModel obra;

  const EditarObraView({super.key, required this.obra});

  @override
  State<EditarObraView> createState() => _EditarObraViewState();
}

class _EditarObraViewState extends State<EditarObraView> {
  late final TextEditingController _nombreController;

  late final TextEditingController _direccionController;

  final ObraController _obraController = ObraController();

  bool _cargando = false;

  double? _latitud;
  double? _longitud;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.obra.nombre);

    _direccionController = TextEditingController(
      text: widget.obra.direccion ?? '',
    );

    // Recuperamos las coordenadas existentes.
    _latitud = widget.obra.latitud;
    _longitud = widget.obra.longitud;
  }

  // ============================================================
  // SELECCIONAR UBICACIÓN
  // ============================================================

  Future<void> _seleccionarEnMapa() async {
    final resultado = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionView(
          latitudInicial: _latitud,
          longitudInicial: _longitud,
        ),
      ),
    );

    if (resultado == null || !mounted) {
      return;
    }

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
  // EDITAR OBRA
  // ============================================================

  Future<void> _editarObra() async {
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
      // COMPROBAR NOMBRE
      // ----------------------------------------------------------

      /*
       * Solo comprobamos duplicado si el nombre cambió.
       */
      if (nombre.toLowerCase() != widget.obra.nombre.toLowerCase()) {
        final existe = await _obraController.existeObraConNombre(nombre);

        if (existe) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ya existe una obra con el nombre "$nombre"'),
            ),
          );

          return;
        }
      }

      // ----------------------------------------------------------
      // ACTUALIZAR
      // ----------------------------------------------------------

      await _obraController.editarObra(
        idObra: widget.obra.idObra,
        nombre: nombre,
        direccion: direccion,
        latitud: _latitud,
        longitud: _longitud,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obra actualizada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al editar la obra: $e')));
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
      appBar: AppBar(title: const Text('Editar obra')),

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

              decoration: const InputDecoration(
                labelText: 'Dirección',
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
            // UBICACIÓN
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
            // GUARDAR
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _cargando ? null : _editarObra,

                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,

                        child: CircularProgressIndicator(strokeWidth: 2),
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
