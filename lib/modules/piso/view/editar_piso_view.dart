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

  final List<String> _estados = const [
    'NO INICIADO',
    'OBRA BRUTA',
    'OBRA FINA',
  ];

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.piso.nombre ?? '');

    _estadoSeleccionado = widget.piso.estadoObra;
  }

  // ============================================================
  // TEXTO DEL TIPO
  // ============================================================

  String _textoTipoPiso() {
    switch (widget.piso.tipoPiso) {
      case 'SOTANO':
        return 'Sótano';

      case 'TERRAZA':
        return 'Terraza';

      case 'NORMAL':
        return 'Piso normal';

      default:
        return widget.piso.tipoPiso;
    }
  }

  // ============================================================
  // IDENTIFICADOR DEL NIVEL
  // ============================================================

  String _textoNumeroPiso() {
    if (widget.piso.tipoPiso == 'TERRAZA') {
      return 'Sin número';
    }

    final numero = widget.piso.numeroPiso;

    if (numero == null) {
      return 'Sin número';
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
        estadoObra: _estadoSeleccionado,
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
      appBar: AppBar(title: const Text('Editar piso')),

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
                labelText: 'Nivel',
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
                labelText: 'Estado de la obra',
                border: OutlineInputBorder(),
              ),
              items: _estados.map((estado) {
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
            const Text(
              'El tipo y número del nivel no pueden modificarse '
              'para mantener el orden de la obra.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ==================================================
            // BOTÓN
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _editarPiso,
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
