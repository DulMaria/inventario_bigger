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

  @override
  void initState() {
    super.initState();
    _calcularNumeroPiso();
  }

  // ============================================================
  // CALCULAR NÚMERO AUTOMÁTICO
  // ============================================================

  Future<void> _calcularNumeroPiso() async {
    final pisos = await _pisoController.obtenerPisos(widget.idObra);

    // ----------------------------------------------------------
    // PISOS SUPERIORES / SOBRE LOZA (NORMAL O TERRAZA)
    // ----------------------------------------------------------
    if (_tipoPiso == 'NORMAL' || _tipoPiso == 'TERRAZA') {
      final positivos = pisos
          .where((p) => p.numeroPiso > 0)
          .map((p) => p.numeroPiso)
          .toList();

      if (positivos.isEmpty) {
        _numeroPiso = 1;
      } else {
        positivos.sort();
        _numeroPiso = positivos.last + 1;
      }

      if (mounted) setState(() {});
      return;
    }

    // ----------------------------------------------------------
    // SÓTANOS
    // ----------------------------------------------------------
    if (_tipoPiso == 'SOTANO') {
      final sotanos = pisos
          .where((p) => p.numeroPiso < 0)
          .map((p) => p.numeroPiso)
          .toList();

      if (sotanos.isEmpty) {
        _numeroPiso = -1;
      } else {
        sotanos.sort();
        _numeroPiso = sotanos.first - 1; // sotanos.first es el más negativo (-2 < -1)
      }

      if (mounted) setState(() {});
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
        return _numeroPiso != null ? 'Terraza (Nivel $_numeroPiso)' : 'Terraza';

      default:
        return 'Nivel';
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
      // Calculamos o confirmamos el número
      await _calcularNumeroPiso();

      if (_numeroPiso == null) {
        throw Exception('No se pudo calcular el número de nivel.');
      }

      if (!mounted) return;

      final nombre = nombreIngresado.isEmpty
          ? _nombrePredeterminado()
          : nombreIngresado;

      await _pisoController.crearPiso(
        idObra: widget.idObra,
        nombre: nombre,
        tipoPiso: _tipoPiso,
        numeroPiso: _numeroPiso!,
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
      _nombreController.clear();
    });

    _calcularNumeroPiso();
  }

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
        hint = _numeroPiso != null ? 'Sótano ${_numeroPiso!.abs()}' : 'Sótano 1';
        break;

      case 'TERRAZA':
        hint = _numeroPiso != null ? 'Terraza (Nivel $_numeroPiso)' : 'Terraza';
        break;

      default:
        hint = _numeroPiso != null ? 'Piso $_numeroPiso' : 'Piso 1';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear piso'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // TIPO
            // ==================================================
            DropdownButtonFormField<String>(
              initialValue: _tipoPiso,
              decoration: const InputDecoration(
                labelText: 'Tipo de nivel / losa',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'NORMAL',
                  child: Text('Piso normal / Departamento'),
                ),
                DropdownMenuItem(
                  value: 'TERRAZA',
                  child: Text('Terraza'),
                ),
                DropdownMenuItem(
                  value: 'SOTANO',
                  child: Text('Sótano (Subterráneo)'),
                ),
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
                labelText: 'Nombre o descripción del piso',
                hintText: hint,
                border: const OutlineInputBorder(),
                helperText: 'Si lo dejas vacío se asignará automáticamente.',
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // INFORMACIÓN DEL NÚMERO
            // ==================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F3FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1D7FAE)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _numeroPiso != null
                          ? 'Nivel asignado automáticamente: Nivel $_numeroPiso'
                          : 'Calculando nivel...',
                      style: const TextStyle(
                        color: Color(0xFF1D7FAE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // BOTÓN
            // ==================================================
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _cargando ? null : _crearPiso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA9E0),
                  foregroundColor: Colors.white,
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear piso',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
