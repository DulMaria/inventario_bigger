import 'package:flutter/material.dart';

import '../../../models/material_model.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../../material/controller/material_controller.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';

class RevisarSolicitudObreroView extends StatefulWidget {
  final SolicitudObreroModel solicitud;
  final int idTecnicoUsuario;

  const RevisarSolicitudObreroView({
    super.key,
    required this.solicitud,
    required this.idTecnicoUsuario,
  });

  @override
  State<RevisarSolicitudObreroView> createState() =>
      _RevisarSolicitudObreroViewState();
}

class _RevisarSolicitudObreroViewState
    extends State<RevisarSolicitudObreroView> {
  final SolicitudObreroController _solicitudObreroController =
      SolicitudObreroController();
  final MaterialController _materialController = MaterialController();

  List<Map<String, dynamic>> _materialesEditables = [];
  final TextEditingController _observacionController = TextEditingController();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _materialesEditables = widget.solicitud.detalles.map((d) {
      return {
        'id_material': d.idMaterial,
        'material': d.material?.nombre ?? 'Material',
        'codigo': d.material?.codigo ?? '',
        'cantidad': d.cantidad,
      };
    }).toList();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  // ============================================================
  // EDITAR CANTIDAD Y/O MATERIAL
  // ============================================================

  Future<void> _editarItem(int index) async {
    final item = _materialesEditables[index];

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _EditarMaterialDialog(
          controller: _materialController,
          idMaterialActual: item['id_material'] as int,
          materialActual: item['material'].toString(),
          codigoActual: item['codigo'].toString(),
          cantidadActual: item['cantidad'] as int,
        );
      },
    );

    if (resultado == null || !mounted) return;

    final MaterialModel material = resultado['material'];
    final int cantidad = resultado['cantidad'];

    // Verificar si ya existe en otra posición
    final yaExiste = _materialesEditables.asMap().entries.any((entry) {
      return entry.key != index &&
          entry.value['id_material'] == material.idMaterial;
    });

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material ya está en la lista.')),
      );
      return;
    }

    setState(() {
      final nuevaLista = List<Map<String, dynamic>>.from(_materialesEditables);
      nuevaLista[index] = {
        'id_material': material.idMaterial,
        'material': material.nombre,
        'codigo': material.codigo,
        'cantidad': cantidad,
      };
      _materialesEditables = nuevaLista;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${material.nombre} actualizado a cantidad: $cantidad')),
    );
  }

  // ============================================================
  // ELIMINAR MATERIAL
  // ============================================================

  Future<void> _eliminarItem(int index) async {
    final item = _materialesEditables[index];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar material'),
          content: Text(
            '¿Deseas quitar "${item['material']}" de esta solicitud?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true && mounted) {
      setState(() {
        final nuevaLista = List<Map<String, dynamic>>.from(_materialesEditables);
        nuevaLista.removeAt(index);
        _materialesEditables = nuevaLista;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['material']} eliminado.')),
      );
    }
  }

  // ============================================================
  // AGREGAR MATERIAL EXTRA (Con autocomplete predictivo)
  // ============================================================

  Future<void> _agregarMaterialExtra() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _AgregarMaterialDialog(controller: _materialController);
      },
    );

    if (resultado == null || !mounted) return;

    final MaterialModel mat = resultado['material'];
    final int cant = resultado['cantidad'];

    final indexExistente =
        _materialesEditables.indexWhere((m) => m['id_material'] == mat.idMaterial);

    if (indexExistente != -1) {
      setState(() {
        final nuevaLista = List<Map<String, dynamic>>.from(_materialesEditables);
        final cantActual = nuevaLista[indexExistente]['cantidad'] as int;
        nuevaLista[indexExistente]['cantidad'] = cantActual + cant;
        _materialesEditables = nuevaLista;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${mat.nombre} ya existía. Cantidad actualizada a ${_materialesEditables[indexExistente]['cantidad']}'),
        ),
      );
      return;
    }

    setState(() {
      final nuevaLista = List<Map<String, dynamic>>.from(_materialesEditables);
      nuevaLista.add({
        'id_material': mat.idMaterial,
        'material': mat.nombre,
        'codigo': mat.codigo,
        'cantidad': cant,
      });
      _materialesEditables = nuevaLista;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mat.nombre} añadido a la solicitud.')),
    );
  }

  // ============================================================
  // APROBAR
  // ============================================================

  Future<void> _aprobar() async {
    if (_materialesEditables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes incluir al menos un material para aprobar.'),
        ),
      );
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      await _solicitudObreroController.aprobarSolicitud(
        idSolicitudObrero: widget.solicitud.idSolicitudObrero,
        idPiso: widget.solicitud.idPiso,
        idTecnicoUsuario: widget.idTecnicoUsuario,
        materiales: _materialesEditables,
        observacion: _observacionController.text.trim().isNotEmpty
            ? _observacionController.text.trim()
            : 'Aprobado y verificado por técnico',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Solicitud aprobada y enviada a Compras correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al aprobar: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // RECHAZAR
  // ============================================================

  Future<void> _rechazar() async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rechazar Solicitud'),
          content: TextField(
            controller: motivoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo del rechazo',
              hintText: 'Explica el motivo al obrero...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = motivoController.text.trim();
                if (txt.isNotEmpty) {
                  Navigator.pop(ctx, txt);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (motivo != null && motivo.isNotEmpty && mounted) {
      setState(() {
        _procesando = true;
      });

      try {
        await _solicitudObreroController.rechazarSolicitud(
          idSolicitudObrero: widget.solicitud.idSolicitudObrero,
          observacion: motivo,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud rechazada.')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _procesando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al rechazar: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitante = widget.solicitud.usuario != null
        ? '${widget.solicitud.usuario!.nombre} ${widget.solicitud.usuario!.apellido}'
        : 'Obrero #${widget.solicitud.idUsuario}';

    final pisoTexto = widget.solicitud.piso?.etiquetaNivel ?? 'Piso';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Revisar Solicitud'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Información General
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE1F3FC),
                          child: Icon(
                            Icons.engineering,
                            color: Color(0xFF2FA9E0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                solicitante,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                pisoTexto,
                                style: const TextStyle(
                                  color: Color(0xFF1D7FAE),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fecha: ${widget.solicitud.fecha.day}/${widget.solicitud.fecha.month}/${widget.solicitud.fecha.year} ${widget.solicitud.fecha.hour.toString().padLeft(2, '0')}:${widget.solicitud.fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C8A93),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Encabezado de Materiales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Materiales (${_materialesEditables.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A32),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _procesando ? null : _agregarMaterialExtra,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir ítem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2FA9E0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Lista de Materiales
            if (_materialesEditables.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No hay materiales en la solicitud. Añade uno con el botón superior.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else
              ...List.generate(_materialesEditables.length, (idx) {
                final mat = _materialesEditables[idx];

                return Card(
                  key: ValueKey('${mat['id_material']}_${mat['material']}_$idx'),
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F3FC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF2FA9E0),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      mat['material'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${mat['codigo']} • Cantidad: ${mat['cantidad']}',
                      style: const TextStyle(
                        color: Color(0xFF1D7FAE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF2FA9E0)),
                          tooltip: 'Editar ítem',
                          onPressed: _procesando ? null : () => _editarItem(idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Eliminar ítem',
                          onPressed:
                              _procesando ? null : () => _eliminarItem(idx),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Observación
            TextField(
              controller: _observacionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observación del Técnico (Opcional)',
                hintText: 'Añade notas o justificaciones de cambios...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de Acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _procesando ? null : _rechazar,
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text(
                      'Rechazar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _procesando ? null : _aprobar,
                    icon: _procesando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text(
                      'Aprobar y Enviar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA9E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MODAL AÑADIR MATERIAL CON AUTOCOMPLETE Y SUGERENCIAS
// ============================================================

class _AgregarMaterialDialog extends StatefulWidget {
  final MaterialController controller;

  const _AgregarMaterialDialog({required this.controller});

  @override
  State<_AgregarMaterialDialog> createState() => _AgregarMaterialDialogState();
}

class _AgregarMaterialDialogState extends State<_AgregarMaterialDialog> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  List<MaterialModel> _sugerencias = [];
  MaterialModel? _materialSeleccionado;
  bool _guardando = false;
  bool _buscandoSugerencias = false;
  String? _errorTexto;

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _onNombreChanged(String valor) async {
    _materialSeleccionado = null;
    setState(() {
      _errorTexto = null;
    });

    if (valor.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _sugerencias = [];
        });
      }
      return;
    }

    setState(() {
      _buscandoSugerencias = true;
    });

    final sugerencias = await widget.controller.buscarSugerencias(valor);

    if (mounted) {
      setState(() {
        _sugerencias = sugerencias;
        _buscandoSugerencias = false;
      });
    }
  }

  void _seleccionarMaterial(MaterialModel mat) {
    setState(() {
      _materialSeleccionado = mat;
      _nombreController.text = mat.nombre;
      _sugerencias = [];
      _errorTexto = null;
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _errorTexto = 'Ingresa o selecciona un material.';
      });
      return;
    }

    if (cantidadTexto.isEmpty) {
      setState(() {
        _errorTexto = 'Ingresa la cantidad.';
      });
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      setState(() {
        _errorTexto = 'La cantidad debe ser un número mayor a 0.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errorTexto = null;
    });

    try {
      MaterialModel? material = _materialSeleccionado;

      if (material == null) {
        material = await widget.controller.buscarMaterial(nombre);
        material ??= await widget.controller.crearMaterial(nombre);
      }

      if (!mounted) return;
      Navigator.pop(context, {'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorTexto = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir material extra'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorTexto != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorTexto!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
              TextField(
                controller: _nombreController,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onNombreChanged,
                decoration: InputDecoration(
                  labelText: 'Nombre del material',
                  hintText: 'Ej. Hormigón, Cemento, Ladrillo...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscandoSugerencias
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_sugerencias.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _sugerencias.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _sugerencias[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_2_outlined,
                            size: 18, color: Color(0xFF2FA9E0)),
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(item.codigo ?? '',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () => _seleccionarMaterial(item),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _cantidadController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 20',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2FA9E0),
            foregroundColor: Colors.white,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Añadir'),
        ),
      ],
    );
  }
}

// ============================================================
// MODAL EDITAR MATERIAL (Optimizado: Inmediato sin lag)
// ============================================================

class _EditarMaterialDialog extends StatefulWidget {
  final MaterialController controller;
  final int idMaterialActual;
  final String materialActual;
  final String codigoActual;
  final int cantidadActual;

  const _EditarMaterialDialog({
    required this.controller,
    required this.idMaterialActual,
    required this.materialActual,
    required this.codigoActual,
    required this.cantidadActual,
  });

  @override
  State<_EditarMaterialDialog> createState() => _EditarMaterialDialogState();
}

class _EditarMaterialDialogState extends State<_EditarMaterialDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _cantidadController;

  List<MaterialModel> _sugerencias = [];
  MaterialModel? _materialSeleccionado;
  bool _guardando = false;
  bool _buscandoSugerencias = false;
  String? _errorTexto;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.materialActual);
    _cantidadController =
        TextEditingController(text: widget.cantidadActual.toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _onNombreChanged(String valor) async {
    _materialSeleccionado = null;
    setState(() {
      _errorTexto = null;
    });

    if (valor.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _sugerencias = [];
        });
      }
      return;
    }

    setState(() {
      _buscandoSugerencias = true;
    });

    final sugerencias = await widget.controller.buscarSugerencias(valor);

    if (mounted) {
      setState(() {
        _sugerencias = sugerencias;
        _buscandoSugerencias = false;
      });
    }
  }

  void _seleccionarMaterial(MaterialModel mat) {
    setState(() {
      _materialSeleccionado = mat;
      _nombreController.text = mat.nombre;
      _sugerencias = [];
      _errorTexto = null;
    });
  }

  void _incrementar() {
    final actual = int.tryParse(_cantidadController.text.trim()) ?? 0;
    setState(() {
      _cantidadController.text = (actual + 1).toString();
      _errorTexto = null;
    });
  }

  void _decrementar() {
    final actual = int.tryParse(_cantidadController.text.trim()) ?? 1;
    if (actual > 1) {
      setState(() {
        _cantidadController.text = (actual - 1).toString();
        _errorTexto = null;
      });
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _errorTexto = 'Ingresa el nombre del material.';
      });
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      setState(() {
        _errorTexto = 'La cantidad debe ser un número mayor a 0.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errorTexto = null;
    });

    try {
      MaterialModel? material = _materialSeleccionado;

      if (material == null && nombre == widget.materialActual) {
        material = MaterialModel(
          idMaterial: widget.idMaterialActual,
          nombre: widget.materialActual,
          codigo: widget.codigoActual,
        );
      } else if (material == null) {
        material = await widget.controller.buscarMaterial(nombre);
        material ??= await widget.controller.crearMaterial(nombre);
      }

      if (!mounted) return;
      Navigator.pop(context, {'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorTexto = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar material y cantidad'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorTexto != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorTexto!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
              TextField(
                controller: _nombreController,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onNombreChanged,
                decoration: InputDecoration(
                  labelText: 'Material',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscandoSugerencias
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_sugerencias.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _sugerencias.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _sugerencias[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_2_outlined,
                            size: 18, color: Color(0xFF2FA9E0)),
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(item.codigo ?? '',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () => _seleccionarMaterial(item),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Cantidad aprobada:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _guardando ? null : _decrementar,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cantidadController,
                      enabled: !_guardando,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _guardando ? null : _incrementar,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2FA9E0),
            foregroundColor: Colors.white,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
