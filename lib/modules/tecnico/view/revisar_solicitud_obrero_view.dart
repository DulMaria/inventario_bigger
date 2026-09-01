import 'package:flutter/material.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';
import '../../material/controller/material_controller.dart';
import '../../../models/material_model.dart';

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

  late List<Map<String, dynamic>> _materialesEditables;
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
  // EDITAR CANTIDAD O MATERIAL
  // ============================================================

  Future<void> _editarItem(int index) async {
    final item = _materialesEditables[index];
    final cantidadController =
        TextEditingController(text: item['cantidad'].toString());

    final resultado = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Editar cantidad - ${item['material']}'),
          content: TextField(
            controller: cantidadController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Cantidad aprobada',
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
                final cant = int.tryParse(cantidadController.text.trim());
                if (cant != null && cant > 0) {
                  Navigator.pop(ctx, cant);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != null && mounted) {
      setState(() {
        _materialesEditables[index]['cantidad'] = resultado;
      });
    }
  }

  void _eliminarItem(int index) {
    setState(() {
      _materialesEditables.removeAt(index);
    });
  }

  // ============================================================
  // AGREGAR MATERIAL EXTRA
  // ============================================================

  Future<void> _agregarMaterialExtra() async {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Añadir material extra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del material',
                  hintText: 'Ej. Cemento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 10',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final cant = int.tryParse(cantidadController.text.trim());
                if (nombre.isNotEmpty && cant != null && cant > 0) {
                  MaterialModel? mat =
                      await _materialController.buscarMaterial(nombre);
                  mat ??= await _materialController.crearMaterial(nombre);

                  if (ctx.mounted) {
                    Navigator.pop(ctx, {
                      'material': mat,
                      'cantidad': cant,
                    });
                  }
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    if (resultado != null && mounted) {
      final MaterialModel mat = resultado['material'];
      final int cant = resultado['cantidad'];

      final yaEsta = _materialesEditables
          .any((m) => m['id_material'] == mat.idMaterial);
      if (yaEsta) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este material ya está en la lista.')),
        );
        return;
      }

      setState(() {
        _materialesEditables.add({
          'id_material': mat.idMaterial,
          'material': mat.nombre,
          'codigo': mat.codigo,
          'cantidad': cant,
        });
      });
    }
  }

  // ============================================================
  // APROBAR
  // ============================================================

  Future<void> _aprobar() async {
    if (_materialesEditables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aprobar al menos un material.'),
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
          content: Text('Solicitud aprobada y enviada a Compras correctamente.'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final txt = motivoController.text.trim();
                if (txt.isNotEmpty) {
                  Navigator.pop(ctx, txt);
                }
              },
              child: const Text('Confirmar Rechazo'),
            ),
          ],
        );
      },
    );

    if (motivo == null || motivo.trim().isEmpty) return;

    setState(() {
      _procesando = true;
    });

    try {
      await _solicitudObreroController.rechazarSolicitud(
        idSolicitudObrero: widget.solicitud.idSolicitudObrero,
        observacion: motivo.trim(),
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

  @override
  Widget build(BuildContext context) {
    final solicitante = widget.solicitud.usuario != null
        ? '${widget.solicitud.usuario!.nombre} ${widget.solicitud.usuario!.apellido}'
        : 'Obrero #${widget.solicitud.idUsuario}';

    final pisoTexto = widget.solicitud.piso != null
        ? '${widget.solicitud.piso!.nombre ?? 'Piso'} (Nivel ${widget.solicitud.piso!.numeroPiso})'
        : 'Piso #${widget.solicitud.idPiso}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Revisar Solicitud de Obrero'),
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
                const Text(
                  'Materiales Solicitados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A32),
                  ),
                ),
                TextButton.icon(
                  onPressed: _procesando ? null : _agregarMaterialExtra,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir ítem'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Lista de Materiales
            ..._materialesEditables.asMap().entries.map((entry) {
              final idx = entry.key;
              final mat = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    mat['material'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Cantidad: ${mat['cantidad']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF2FA9E0)),
                        tooltip: 'Editar cantidad',
                        onPressed: _procesando ? null : () => _editarItem(idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: 'Quitar',
                        onPressed:
                            _procesando ? null : () => _eliminarItem(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Campo de Observación
            TextField(
              controller: _observacionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observación para Compras / Obrero (Opcional)',
                hintText: 'Ej. Cantidad aprobada de acuerdo al avance.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de Acción
            if (_procesando)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rechazar,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Rechazar',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _aprobar,
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar y Enviar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA9E0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
