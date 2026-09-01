import 'package:flutter/material.dart';

import '../../../models/material_model.dart';
import '../../../models/piso_model.dart';
import '../../../models/solicitud_model.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../controller/material_controller.dart';
import '../../solicitud/controller/solicitud_controller.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';

class MaterialesView extends StatefulWidget {
  final int idObra;
  final int idPiso;
  final int idUsuario;
  final int idRol; // 1: Obrero, 2: Técnico
  final PisoModel? piso;

  const MaterialesView({
    super.key,
    required this.idObra,
    required this.idPiso,
    required this.idUsuario,
    this.idRol = 1,
    this.piso,
  });

  @override
  State<MaterialesView> createState() => _MaterialesViewState();
}

class _MaterialesViewState extends State<MaterialesView>
    with SingleTickerProviderStateMixin {
  final MaterialController _controller = MaterialController();
  final SolicitudController _solicitudController = SolicitudController();
  final SolicitudObreroController _solicitudObreroController =
      SolicitudObreroController();

  final List<Map<String, dynamic>> _solicitud = [];
  List<SolicitudObreroModel> _solicitudesPreviasObrero = [];
  List<SolicitudModel> _solicitudesPreviasTecnico = [];

  bool _enviandoSolicitud = false;
  bool _cargando = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      if (widget.idRol == 1) {
        final previas =
            await _solicitudObreroController.obtenerSolicitudesPorPiso(
          idPiso: widget.idPiso,
          idUsuario: widget.idUsuario,
        );
        if (mounted) {
          setState(() {
            _solicitudesPreviasObrero = previas;
          });
        }
      } else {
        final previas = await _solicitudController.obtenerSolicitudesPorPiso(
          idPiso: widget.idPiso,
          idUsuario: widget.idUsuario,
        );
        if (mounted) {
          setState(() {
            _solicitudesPreviasTecnico = previas;
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _mostrarAgregarMaterial() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AgregarMaterialDialog(controller: _controller);
      },
    );

    if (!mounted || resultado == null) return;

    final MaterialModel material = resultado['material'];
    final int cantidad = resultado['cantidad'];

    final yaAgregado = _solicitud.any(
      (item) => item['id_material'] == material.idMaterial,
    );

    if (yaAgregado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Este material ya está en la lista actual.')),
      );
      return;
    }

    setState(() {
      _solicitud.add({
        'id_material': material.idMaterial,
        'material': material.nombre,
        'codigo': material.codigo,
        'cantidad': cantidad,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${material.nombre} añadido a la lista.')),
    );
  }

  Future<void> _editarMaterial(int index) async {
    final item = _solicitud[index];

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _EditarMaterialDialog(
          controller: _controller,
          materialActual: item['material'].toString(),
          cantidadActual: item['cantidad'] as int,
        );
      },
    );

    if (!mounted || resultado == null) return;

    final MaterialModel material = resultado['material'];
    final int cantidad = resultado['cantidad'];

    final yaExiste = _solicitud.asMap().entries.any((entry) {
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
      _solicitud[index] = {
        'id_material': material.idMaterial,
        'material': material.nombre,
        'codigo': material.codigo,
        'cantidad': cantidad,
      };
    });
  }

  void _eliminarMaterial(int index) {
    setState(() {
      _solicitud.removeAt(index);
    });
  }

  Future<void> _enviarSolicitud() async {
    if (_solicitud.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Añade al menos un material antes de enviar.')),
      );
      return;
    }

    setState(() {
      _enviandoSolicitud = true;
    });

    try {
      if (widget.idRol == 2) {
        // TÉCNICO: Directo a Compras
        await _solicitudController.crearSolicitud(
          idPiso: widget.idPiso,
          idUsuario: widget.idUsuario,
          materiales: _solicitud,
        );
      } else {
        // OBRERO: Pasa a revisión del rol Técnico en estado PENDIENTE
        await _solicitudObreroController.crearSolicitudObrero(
          idPiso: widget.idPiso,
          idUsuario: widget.idUsuario,
          materiales: _solicitud,
        );
      }

      if (!mounted) return;

      setState(() {
        _solicitud.clear();
        _enviandoSolicitud = false;
      });

      final String mensajeExito = widget.idRol == 2
          ? 'Pedido enviado directamente a Compras.'
          : 'Solicitud enviada al Técnico para su revisión.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeExito)),
      );

      // Recargar solicitudes previas para el piso
      _cargarDatos();

      _tabController.animateTo(1); // Cambiar a la pestaña de historial en el piso
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviandoSolicitud = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return Colors.orange.shade800;
      case 'APROBADA':
        return Colors.green.shade700;
      case 'RECHAZADA':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Color _fondoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return Colors.orange.shade50;
      case 'APROBADA':
        return Colors.green.shade50;
      case 'RECHAZADA':
        return Colors.red.shade50;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return 'Pendiente';
      case 'APROBADA':
        return 'Aprobada';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int cantidadEnviados = widget.idRol == 1
        ? _solicitudesPreviasObrero.length
        : _solicitudesPreviasTecnico.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.piso != null
              ? widget.piso!.etiquetaNivel
              : 'Materiales del Piso',
        ),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              text: widget.idRol == 2 ? 'Pedir a Compras' : 'Solicitar Material',
            ),
            Tab(
              icon: const Icon(Icons.history, size: 20),
              text: 'Enviados ($cantidadEnviados)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVistaSolicitar(),
          _buildVistaHistorialPiso(),
        ],
      ),
    );
  }

  Widget _buildVistaSolicitar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.idRol == 2
                    ? 'Materiales para Compras'
                    : 'Materiales a solicitar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A32),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _enviandoSolicitud ? null : _mostrarAgregarMaterial,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
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
          const SizedBox(height: 12),
          Expanded(
            child: _solicitud.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Color(0xFFB7C5CC),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No has añadido materiales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.idRol == 2
                                ? 'Toca "Añadir" para registrar materiales que solicitarás al encargado de compras para este piso.'
                                : 'Toca "Añadir" para buscar o registrar los materiales necesarios para este piso.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF7C8A93)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _solicitud.length,
                    itemBuilder: (context, index) {
                      final item = _solicitud[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F3FC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.construction,
                              color: Color(0xFF2FA9E0),
                            ),
                          ),
                          title: Text(
                            item['material'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${item['codigo']} • Cantidad: ${item['cantidad']}',
                            style: const TextStyle(color: Color(0xFF7C8A93)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Color(0xFF2FA9E0)),
                                onPressed: () => _editarMaterial(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _eliminarMaterial(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_solicitud.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _enviandoSolicitud ? null : _enviarSolicitud,
                icon: _enviandoSolicitud
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  widget.idRol == 2
                      ? 'Enviar directamente a Compras'
                      : 'Enviar solicitud al Técnico',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA9E0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVistaHistorialPiso() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool esObrero = widget.idRol == 1;
    final int totalEnviados = esObrero
        ? _solicitudesPreviasObrero.length
        : _solicitudesPreviasTecnico.length;

    if (totalEnviados == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history_toggle_off,
                size: 64,
                color: Color(0xFFB7C5CC),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin envíos en este piso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A32),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                esObrero
                    ? 'Los materiales que solicites en este nivel aparecerán aquí para que sepas qué pedidos enviaste y si el técnico ya los aprobó.'
                    : 'Los pedidos que envíes a compras para este piso aparecerán aquí con el detalle de materiales solicitados.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7C8A93)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: totalEnviados,
        itemBuilder: (context, index) {
          final fecha = esObrero
              ? _solicitudesPreviasObrero[index].fecha
              : _solicitudesPreviasTecnico[index].fecha;

          final estado = esObrero
              ? _solicitudesPreviasObrero[index].estado
              : _solicitudesPreviasTecnico[index].estado;

          final observacion = esObrero
              ? _solicitudesPreviasObrero[index].observacion
              : _solicitudesPreviasTecnico[index].observacion;

          final List<Widget> itemsDetalle = esObrero
              ? _solicitudesPreviasObrero[index].detalles.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF2FA9E0),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.material?.nombre ?? 'Material',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'Cant: ${d.cantidad}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D7FAE),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
              : _solicitudesPreviasTecnico[index].detalles.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF2FA9E0),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.material?.nombre ?? 'Material',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'Cant: ${d.cantidad}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D7FAE),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6B73),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _fondoEstado(estado),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _colorEstado(estado).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _textoEstado(estado),
                          style: TextStyle(
                            color: _colorEstado(estado),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...itemsDetalle,
                  if (observacion != null &&
                      observacion.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: estado == 'RECHAZADA'
                            ? Colors.red.shade50
                            : const Color(0xFFF4FAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Observación: $observacion',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: estado == 'RECHAZADA'
                              ? Colors.red.shade900
                              : const Color(0xFF1D7FAE),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _onNombreChanged(String valor) async {
    _materialSeleccionado = null;
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
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Ingresa o selecciona un material.');
      return;
    }

    if (cantidadTexto.isEmpty) {
      _mostrarError('Ingresa la cantidad.');
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      _mostrarError('La cantidad debe ser un número mayor a 0.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      MaterialModel? material = _materialSeleccionado;

      if (material == null) {
        material = await widget.controller.buscarMaterial(nombre);
        material ??= await widget.controller.crearMaterial(nombre);
      }

      if (!mounted) return;
      Navigator.of(context).pop({'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir material'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  labelText: 'Cantidad a solicitar',
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
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
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
// MODAL EDITAR MATERIAL
// ============================================================

class _EditarMaterialDialog extends StatefulWidget {
  final MaterialController controller;
  final String materialActual;
  final int cantidadActual;

  const _EditarMaterialDialog({
    required this.controller,
    required this.materialActual,
    required this.cantidadActual,
  });

  @override
  State<_EditarMaterialDialog> createState() => _EditarMaterialDialogState();
}

class _EditarMaterialDialogState extends State<_EditarMaterialDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _cantidadController;
  bool _guardando = false;

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

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Ingresa el nombre del material.');
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      _mostrarError('La cantidad debe ser un número mayor a 0.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      MaterialModel? material = await widget.controller.buscarMaterial(nombre);
      material ??= await widget.controller.crearMaterial(nombre);

      if (!mounted) return;
      Navigator.of(context).pop({'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar material'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cantidadController,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
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
