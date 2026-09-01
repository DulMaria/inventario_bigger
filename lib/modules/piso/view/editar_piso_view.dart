import 'package:flutter/material.dart';

import '../../../models/piso_model.dart';
import '../controller/piso_controller.dart';

class EditarPisoView extends StatefulWidget {
  final PisoModel piso;

  const EditarPisoView({super.key, required this.piso});

  @override
  State<EditarPisoView> createState() => _EditarPisoViewState();
}

class _EditarPisoViewState extends State<EditarPisoView> {
  late final TextEditingController _nombreController;

  final PisoController _pisoController = PisoController();

  late String _estadoSeleccionado;

  bool _cargando = false;

  late List<String> _estadosPermitidos;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.piso.nombre ?? '');
    _estadoSeleccionado = widget.piso.estadoObra;
    _estadosPermitidos = _pisoController.obtenerEstadosPermitidos(widget.piso.estadoObra);
  }

  // ============================================================
  // TEXTO DEL TIPO
  // ============================================================

  String _textoTipoPiso() {
    switch (widget.piso.tipoPiso) {
      case 'SOTANO':
        return 'Sótano (Subterráneo)';

      case 'TERRAZA':
        return 'Terraza';

      case 'NORMAL':
        return 'Piso normal / Departamento';

      default:
        return widget.piso.tipoPiso;
    }
  }

  // ============================================================
  // IDENTIFICADOR DEL NIVEL
  // ============================================================

  String _textoNumeroPiso() {
    final numero = widget.piso.numeroPiso;

    if (widget.piso.tipoPiso == 'TERRAZA') {
      return 'Terraza (Nivel $numero)';
    }

    if (widget.piso.tipoPiso == 'SOTANO') {
      return 'Sótano ${numero.abs()}';
    }

    return 'Piso $numero';
  }

  // ============================================================
  // EDITAR
  // ============================================================

  Future<void> _editarPiso() async {
    final nombre = _nombreController.text.trim();

    setState(() {
      _cargando = true;
    });

    try {
      await _pisoController.editarPiso(
        idPiso: widget.piso.idPiso,
        idObra: widget.piso.obra.idObra,
        nombre: nombre,
        estadoActual: widget.piso.estadoObra,
        nuevoEstadoObra: _estadoSeleccionado,
        tipoPiso: widget.piso.tipoPiso,
        numeroPiso: widget.piso.numeroPiso,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piso actualizado correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar el piso: '
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar piso'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // TIPO
            // ==================================================
            TextFormField(
              initialValue: _textoTipoPiso(),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de nivel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // NÚMERO
            // ==================================================
            TextFormField(
              initialValue: _textoNumeroPiso(),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nivel / Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // NOMBRE
            // ==================================================
            TextField(
              controller: _nombreController,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del piso',
                hintText: 'Ej. Piso 1',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ESTADO
            // ==================================================
            DropdownButtonFormField<String>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Estado de la obra (Avance sucesivo)',
                border: OutlineInputBorder(),
                helperText: 'Solo puedes avanzar de forma sucesiva.',
              ),
              items: _estadosPermitidos.map((estado) {
                return DropdownMenuItem<String>(
                  value: estado,
                  child: Text(estado),
                );
              }).toList(),
              onChanged: _cargando
                  ? null
                  : (valor) {
                      if (valor == null) return;
                      setState(() {
                        _estadoSeleccionado = valor;
                      });
                    },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INFORMACIÓN
            // ==================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAFE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2FA9E0).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF7C8A93)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El tipo y número de nivel se mantienen fijos para garantizar la integridad estructural de la obra.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
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
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _cargando ? null : _editarPiso,
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
                        'Guardar cambios',
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
