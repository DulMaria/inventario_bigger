import 'package:flutter/material.dart';

import '../controller/piso_controller.dart';

class CrearPisoView extends StatefulWidget {
  final int idObra;

  const CrearPisoView({super.key, required this.idObra});

  @override
  State<CrearPisoView> createState() => _CrearPisoViewState();
}

class _CrearPisoViewState extends State<CrearPisoView> {
  final PisoController _pisoController = PisoController();

  final TextEditingController _nombreController = TextEditingController();

  String _tipoPiso = 'NORMAL';

  bool _cargando = false;

  int? _numeroPiso;

  // ============================================================
  // CALCULAR NÚMERO AUTOMÁTICO
  // ============================================================

  Future<void> _calcularNumeroPiso() async {
    final pisos = await _pisoController.obtenerPisos(widget.idObra);

    // ----------------------------------------------------------
    // TERRAZA
    // ----------------------------------------------------------
    // Las terrazas NO tienen número de piso.
    if (_tipoPiso == 'TERRAZA') {
      _numeroPiso = null;
      return;
    }

    // ----------------------------------------------------------
    // PISOS NORMALES
    // ----------------------------------------------------------
    if (_tipoPiso == 'NORMAL') {
      final normales = pisos
          .where((p) => p.tipoPiso == 'NORMAL')
          .map((p) => p.numeroPiso)
          .whereType<int>()
          .where((n) => n > 0)
          .toList();

      if (normales.isEmpty) {
        _numeroPiso = 1;
      } else {
        normales.sort();
        _numeroPiso = normales.last + 1;
      }

      return;
    }

    // ----------------------------------------------------------
    // SÓTANOS
    // ----------------------------------------------------------
    if (_tipoPiso == 'SOTANO') {
      final sotanos = pisos
          .where((p) => p.tipoPiso == 'SOTANO')
          .map((p) => p.numeroPiso)
          .whereType<int>()
          .where((n) => n < 0)
          .toList();

      if (sotanos.isEmpty) {
        _numeroPiso = -1;
      } else {
        sotanos.sort();
        _numeroPiso = sotanos.first - 1;
      }

      return;
    }
  }

  // ============================================================
  // NOMBRE PREDETERMINADO
  // ============================================================

  String _nombrePredeterminado() {
    switch (_tipoPiso) {
      case 'NORMAL':
        return _numeroPiso != null ? 'Piso $_numeroPiso' : 'Piso';

      case 'SOTANO':
        return _numeroPiso != null ? 'Sótano ${_numeroPiso!.abs()}' : 'Sótano';

      case 'TERRAZA':
        return 'Terraza';

      default:
        return '';
    }
  }

  // ============================================================
  // CREAR PISO
  // ============================================================

  Future<void> _crearPiso() async {
    final nombreIngresado = _nombreController.text.trim();

    setState(() {
      _cargando = true;
    });

    try {
      // Primero calculamos el número.
      await _calcularNumeroPiso();

      if (!mounted) return;

      // --------------------------------------------------------
      // SI NO ESCRIBIÓ NOMBRE
      // --------------------------------------------------------
      final nombre = nombreIngresado.isEmpty
          ? _nombrePredeterminado()
          : nombreIngresado;

      // --------------------------------------------------------
      // CREAR
      // --------------------------------------------------------
      await _pisoController.crearPiso(
        idObra: widget.idObra,
        nombre: nombre,
        tipoPiso: _tipoPiso,
        numeroPiso: _numeroPiso,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piso creado correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear el piso: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
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

  // ============================================================
  // CAMBIAR TIPO
  // ============================================================

  void _cambiarTipo(String? valor) {
    if (valor == null || _cargando) return;

    setState(() {
      _tipoPiso = valor;
      _numeroPiso = null;

      // Limpiamos el nombre porque cambia el tipo.
      _nombreController.clear();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    String hint;

    switch (_tipoPiso) {
      case 'SOTANO':
        hint = 'Sótano 1';
        break;

      case 'TERRAZA':
        hint = 'Terraza principal';
        break;

      default:
        hint = 'Piso 1';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crear piso')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // TIPO
            // ==================================================

            DropdownButtonFormField<String>(
              initialValue: _tipoPiso,
              decoration: const InputDecoration(
                labelText: 'Tipo de nivel',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'NORMAL', child: Text('Piso normal')),
                DropdownMenuItem(value: 'SOTANO', child: Text('Sótano')),
                DropdownMenuItem(value: 'TERRAZA', child: Text('Terraza')),
              ],
              onChanged: _cargando ? null : _cambiarTipo,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // NOMBRE
            // ==================================================
            TextField(
              controller: _nombreController,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: hint,
                border: const OutlineInputBorder(),
                helperText: 'Si lo dejas vacío se asignará automáticamente.',
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // INFORMACIÓN DEL NÚMERO
            // ==================================================
            if (_tipoPiso == 'TERRAZA')
              const Text('Las terrazas no utilizan número de piso.')
            else
              const Text('El número de piso se asignará automáticamente.'),

            const SizedBox(height: 24),

            // ==================================================
            // BOTÓN
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _crearPiso,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear piso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
