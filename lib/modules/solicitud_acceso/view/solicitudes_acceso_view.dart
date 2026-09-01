// lib/modules/solicitud_acceso/view/solicitudes_acceso_view.dart
import 'package:flutter/material.dart';
import '../controller/solicitud_acceso_controller.dart';
import '../../../models/obra_model.dart';
import '../../obra/controller/obra_controller.dart';

class SolicitudesAccesoView extends StatefulWidget {
  final int? idObra;
  final String? nombreObra;

  const SolicitudesAccesoView({
    super.key,
    this.idObra,
    this.nombreObra,
  });

  @override
  State<SolicitudesAccesoView> createState() => _SolicitudesAccesoViewState();
}

class _SolicitudesAccesoViewState extends State<SolicitudesAccesoView> {
  final SolicitudAccesoController _controller = SolicitudAccesoController();
  final ObraController _obraController = ObraController();

  List<Map<String, dynamic>> _todasLasSolicitudes = [];
  List<Map<String, dynamic>> _roles = [];
  List<ObraModel> _obrasDisponibles = [];

  int? _obraSeleccionadaFiltro;
  String _filtroEstado = 'TODAS'; // 'TODAS', 'PENDIENTE', 'APROBADA', 'RECHAZADA'
  bool _cargando = true;

  bool get _esGerenteObra => widget.idObra != null;

  @override
  void initState() {
    super.initState();
    _obraSeleccionadaFiltro = widget.idObra;
    _cargarDatos();
  }

  // ============================================================
  // CARGAR SOLICITUDES Y ROLES
  // ============================================================

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final solicitudes = await _controller.obtenerSolicitudes(
        idObra: widget.idObra,
      );

      final roles = await _controller.obtenerRoles();

      List<ObraModel> obras = [];
      if (!_esGerenteObra) {
        try {
          obras = await _obraController.obtenerObras();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _todasLasSolicitudes = solicitudes;
        _roles = roles;
        _obrasDisponibles = obras;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las solicitudes: $e')),
      );
    }
  }

  // ============================================================
  // FILTRAR LISTA SEGÚN ESTADO Y OBRA
  // ============================================================

  List<Map<String, dynamic>> get _solicitudesFiltradas {
    return _todasLasSolicitudes.where((s) {
      // Filtro por obra (si no es vista fija de gerente)
      if (!_esGerenteObra && _obraSeleccionadaFiltro != null) {
        final idObraSol = s['id_obra'] as int?;
        if (idObraSol != _obraSeleccionadaFiltro) {
          return false;
        }
      }

      // Filtro por estado
      if (_filtroEstado != 'TODAS') {
        final estado = s['estado']?.toString().toUpperCase() ?? 'PENDIENTE';
        if (estado != _filtroEstado) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // APROBAR SOLICITUD
  // ============================================================

  Future<void> _aprobarSolicitud(Map<String, dynamic> solicitud) async {
    final idSolicitud = solicitud['id_solicitud_acceso'] as int;
    final idUsuario = solicitud['id_usuario'] as int;
    final idObra = solicitud['id_obra'] as int;
    final idRol = solicitud['id_rol_solicitado'] as int;

    setState(() {
      _cargando = true;
    });

    final error = await _controller.aprobarSolicitud(
      idSolicitud: idSolicitud,
      idUsuario: idUsuario,
      idObra: idObra,
      idRol: idRol,
    );

    if (!mounted) return;

    setState(() {
      _cargando = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud aprobada y asignada a la obra correctamente'),
        backgroundColor: Colors.green,
      ),
    );

    await _cargarDatos();
  }

  // ============================================================
  // RECHAZAR SOLICITUD
  // ============================================================

  Future<void> _rechazarSolicitud(Map<String, dynamic> solicitud) async {
    final idSolicitud = solicitud['id_solicitud_acceso'] as int;
    final observacionController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Deseas rechazar esta solicitud de acceso?'),
              const SizedBox(height: 16),
              TextField(
                controller: observacionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observación (Opcional)',
                  hintText: 'Motivo del rechazo...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      observacionController.dispose();
      return;
    }

    setState(() {
      _cargando = true;
    });

    final error = await _controller.rechazarSolicitud(
      idSolicitud: idSolicitud,
      observacion: observacionController.text.trim().isEmpty
          ? null
          : observacionController.text.trim(),
    );

    observacionController.dispose();

    if (!mounted) return;

    setState(() {
      _cargando = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud rechazada'),
        backgroundColor: Colors.orange,
      ),
    );

    await _cargarDatos();
  }

  // ============================================================
  // CAMBIAR ROL Y APROBAR (EXCLUSIVO ADMINISTRADOR)
  // ============================================================

  Future<void> _editarRol(Map<String, dynamic> solicitud) async {
    final idSolicitud = solicitud['id_solicitud_acceso'] as int;
    final idUsuario = solicitud['id_usuario'] as int;
    final idObra = solicitud['id_obra'] as int;

    int? rolSeleccionado = solicitud['id_rol_solicitado'] as int?;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Asignar rol diferente (Admin)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el rol que deseas asignarle a este usuario en la obra:',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol a Asignar',
                      border: OutlineInputBorder(),
                    ),
                    items: _roles.map((rol) {
                      return DropdownMenuItem<int>(
                        value: rol['id_rol'] as int,
                        child: Text(rol['nombre'].toString()),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        rolSeleccionado = valor;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: rolSeleccionado == null
                      ? null
                      : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2FA9E0),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aprobar con este rol'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true || rolSeleccionado == null) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    final error = await _controller.aprobarConRol(
      idSolicitud: idSolicitud,
      idUsuario: idUsuario,
      idObra: idObra,
      idRol: rolSeleccionado!,
    );

    if (!mounted) return;

    setState(() {
      _cargando = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario aprobado con el rol asignado por el Administrador'),
        backgroundColor: Colors.green,
      ),
    );

    await _cargarDatos();
  }

  String _nombreUsuario(Map<String, dynamic> solicitud) {
    final usuario = solicitud['usuarios'] ?? solicitud['usuario'];
    if (usuario == null) return 'Usuario #${solicitud['id_usuario']}';
    final nombre = usuario['nombre'] ?? '';
    final apellido = usuario['apellido'] ?? '';
    final nombreCompleto = '$nombre $apellido'.trim();
    return nombreCompleto.isEmpty ? 'Usuario #${solicitud['id_usuario']}' : nombreCompleto;
  }

  String _telefonoUsuario(Map<String, dynamic> solicitud) {
    final usuario = solicitud['usuarios'] ?? solicitud['usuario'];
    return usuario?['telefono']?.toString() ?? 'Sin teléfono';
  }

  String _nombreObra(Map<String, dynamic> solicitud) {
    final obra = solicitud['obras'] ?? solicitud['obra'];
    return obra?['nombre']?.toString() ?? 'Obra #${solicitud['id_obra']}';
  }

  // ============================================================
  // TARJETA DE SOLICITUD
  // ============================================================

  Widget _buildSolicitud(Map<String, dynamic> solicitud) {
    final estado = solicitud['estado']?.toString().toUpperCase() ?? 'PENDIENTE';
    final nombreUsuario = _nombreUsuario(solicitud);
    final telefono = _telefonoUsuario(solicitud);
    final nombreObra = _nombreObra(solicitud);
    final nombreRol = solicitud['rol_solicitado']?.toString() ?? 'Sin rol';
    final nombreRolAprobado = solicitud['rol_aprobado']?.toString() ?? 'No especificado';
    final idSolicitud = solicitud['id_solicitud_acceso']?.toString() ?? '';

    final fechaStr = solicitud['fecha']?.toString();
    DateTime? fecha;
    if (fechaStr != null) {
      fecha = DateTime.tryParse(fechaStr);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE1F3FC),
                  child: const Icon(Icons.person, color: Color(0xFF2FA9E0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreUsuario,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A32),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📱 $telefono',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                      ),
                      if (fecha != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9EACB4)),
                        ),
                      ],
                    ],
                  ),
                ),
                _EstadoSolicitud(estado: estado),
              ],
            ),
            const Divider(height: 24),

            // Obra
            _DatoSolicitud(
              icono: Icons.business,
              titulo: 'Obra',
              valor: nombreObra,
            ),
            const SizedBox(height: 8),

            _DatoSolicitud(
              icono: Icons.badge_outlined,
              titulo: 'Rol solicitado',
              valor: nombreRol,
            ),

            if (estado == 'APROBADA') ...[
              const SizedBox(height: 8),
              _DatoSolicitud(
                icono: Icons.verified_user_outlined,
                titulo: 'Rol asignado',
                valor: nombreRolAprobado,
              ),
            ],

            const SizedBox(height: 8),
            _DatoSolicitud(
              icono: Icons.tag,
              titulo: 'Solicitud ID',
              valor: '#$idSolicitud',
            ),

            if (solicitud['observacion'] != null &&
                solicitud['observacion'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Observación: ${solicitud['observacion']}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            // BOTONES PARA ESTADO PENDIENTE
            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 16),
              if (_esGerenteObra) ...[
                // VISTA GERENTE: Solo Rechazar y Aceptar con el rol solicitado (NO puede cambiar rol)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : () => _rechazarSolicitud(solicitud),
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : () => _aprobarSolicitud(solicitud),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aceptar solicitud'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // VISTA ADMINISTRADOR: Puede Rechazar, Cambiar rol, o Aceptar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : () => _rechazarSolicitud(solicitud),
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : () => _editarRol(solicitud),
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF2FA9E0)),
                        label: const Text('Cambiar rol', style: TextStyle(color: Color(0xFF2FA9E0))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2FA9E0)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : () => _aprobarSolicitud(solicitud),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar solicitud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.nombreObra != null
        ? 'Solicitudes - ${widget.nombreObra}'
        : 'Solicitudes de Acceso';

    final listaFiltrada = _solicitudesFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de Obra para Administrador (cuando widget.idObra es null)
          if (!_esGerenteObra && _obrasDisponibles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Color(0xFF2FA9E0), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Obra:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _obraSeleccionadaFiltro,
                        isExpanded: true,
                        hint: const Text('Todas las obras'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('🌐 Todas las obras', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._obrasDisponibles.map((o) {
                            return DropdownMenuItem<int?>(
                              value: o.idObra,
                              child: Text(o.nombre),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _obraSeleccionadaFiltro = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Filtros de Estado (Chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('TODAS', 'Todas (${_todasLasSolicitudes.length})'),
                  const SizedBox(width: 8),
                  _buildFiltroChip(
                    'PENDIENTE',
                    'Pendientes (${_todasLasSolicitudes.where((s) => (s['estado'] ?? 'PENDIENTE') == 'PENDIENTE').length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroChip(
                    'APROBADA',
                    'Aprobadas (${_todasLasSolicitudes.where((s) => s['estado'] == 'APROBADA').length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroChip(
                    'RECHAZADA',
                    'Rechazadas (${_todasLasSolicitudes.where((s) => s['estado'] == 'RECHAZADA').length})',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Lista de Solicitudes
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : listaFiltrada.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _cargarDatos,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Color(0xFFB7C5CC),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay solicitudes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E2A32),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'No se encontraron solicitudes con los filtros aplicados.',
                                    style: TextStyle(color: Color(0xFF7C8A93)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarDatos,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) {
                            return _buildSolicitud(listaFiltrada[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String estado, String etiqueta) {
    final bool seleccionado = _filtroEstado == estado;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (val) {
        if (val) {
          setState(() {
            _filtroEstado = estado;
          });
        }
      },
      selectedColor: const Color(0xFF2FA9E0),
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : const Color(0xFF5F6B73),
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

// ============================================================
// DATO DE SOLICITUD
// ============================================================

class _DatoSolicitud extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _DatoSolicitud({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: const Color(0xFF2FA9E0)),
        const SizedBox(width: 8),
        Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E2A32)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ESTADO
// ============================================================

class _EstadoSolicitud extends StatelessWidget {
  final String estado;

  const _EstadoSolicitud({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color fondo;

    switch (estado) {
      case 'APROBADA':
        color = Colors.green.shade700;
        fondo = Colors.green.shade50;
        break;
      case 'RECHAZADA':
        color = Colors.red.shade700;
        fondo = Colors.red.shade50;
        break;
      default:
        color = Colors.orange.shade800;
        fondo = Colors.orange.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}