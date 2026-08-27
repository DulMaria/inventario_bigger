import 'package:flutter/material.dart';

import '../controller/solicitud_acceso_controller.dart';

class SolicitudesAccesoView extends StatefulWidget {
  const SolicitudesAccesoView({super.key});

  @override
  State<SolicitudesAccesoView> createState() => _SolicitudesAccesoViewState();
}

class _SolicitudesAccesoViewState extends State<SolicitudesAccesoView> {
  final SolicitudAccesoController _controller = SolicitudAccesoController();

  List<Map<String, dynamic>> _solicitudes = [];

  List<Map<String, dynamic>> _roles = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
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
      final solicitudes = await _controller.obtenerSolicitudes();

      final roles = await _controller.obtenerRoles();

      print('SOLICITUDES: $solicitudes');

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudes;
        _roles = roles;
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
        content: Text('Solicitud aprobada correctamente'),
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
              const Text('¿Deseas rechazar esta solicitud?'),

              const SizedBox(height: 16),

              TextField(
                controller: observacionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observación',
                  hintText: 'Motivo del rechazo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
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
  // CAMBIAR ROL Y APROBAR
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
              title: const Text('Asignar rol'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el rol que tendrá el usuario en esta obra:',
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    initialValue: rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
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
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancelar'),
                ),

                ElevatedButton(
                  onPressed: rolSeleccionado == null
                      ? null
                      : () {
                          Navigator.pop(context, true);
                        },
                  child: const Text('Aceptar'),
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
        content: Text('Usuario aprobado con el rol seleccionado'),
        backgroundColor: Colors.green,
      ),
    );

    await _cargarDatos();
  }

  // ============================================================
  // OBTENER NOMBRE DE USUARIO
  // ============================================================

  String _nombreUsuario(Map<String, dynamic> solicitud) {
    final usuario = solicitud['usuario'];

    if (usuario == null) {
      return 'Usuario no encontrado';
    }

    final nombre = usuario['nombre'] ?? '';

    final apellido = usuario['apellido'] ?? '';

    return '$nombre $apellido'.trim();
  }

  // ============================================================
  // OBTENER CORREO
  // ============================================================

  String _correoUsuario(Map<String, dynamic> solicitud) {
    final usuario = solicitud['usuario'];

    if (usuario == null) {
      return 'Sin correo';
    }

    return usuario['correo']?.toString() ?? 'Sin correo';
  }

  // ============================================================
  // OBTENER OBRA
  // ============================================================

  String _nombreObra(Map<String, dynamic> solicitud) {
    final obra = solicitud['obra'];

    if (obra == null) {
      return 'Obra no encontrada';
    }

    return obra['nombre']?.toString() ?? 'Sin nombre';
  }

  // ============================================================
  // OBTENER ROL SOLICITADO
  // ============================================================

  String _nombreRol(Map<String, dynamic> solicitud) {
    final rol = solicitud['rol'];

    if (rol == null) {
      return 'Rol no encontrado';
    }

    return rol['nombre']?.toString() ?? 'Sin rol';
  }

  // ============================================================
  // OBTENER ROL APROBADO
  // ============================================================

  String _nombreRolAprobado(Map<String, dynamic> solicitud) {
    final rolAprobado = solicitud['rol_aprobado'];

    if (rolAprobado == null) {
      return 'No especificado';
    }

    return rolAprobado['nombre']?.toString() ?? 'No especificado';
  }

  // ============================================================
  // TARJETA DE SOLICITUD
  // ============================================================

  Widget _buildSolicitud(Map<String, dynamic> solicitud) {
    final estado = solicitud['estado']?.toString() ?? 'PENDIENTE';

    final nombreUsuario = _nombreUsuario(solicitud);

    final correo = _correoUsuario(solicitud);

    final nombreObra = _nombreObra(solicitud);

    final nombreRol = _nombreRol(solicitud);

    final nombreRolAprobado = _nombreRolAprobado(solicitud);

    final idSolicitud = solicitud['id_solicitud_acceso']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CABECERA
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 24, child: Icon(Icons.person)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreUsuario,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        correo,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                _EstadoSolicitud(estado: estado),
              ],
            ),

            const Divider(height: 28),

            // ==================================================
            // INFORMACIÓN
            // ==================================================
            _DatoSolicitud(
              icono: Icons.business,
              titulo: 'Obra',
              valor: nombreObra,
            ),

            const SizedBox(height: 10),

            _DatoSolicitud(
              icono: Icons.badge_outlined,
              titulo: 'Rol solicitado',
              valor: nombreRol,
            ),

            if (estado == 'APROBADA') ...[
              const SizedBox(height: 10),

              _DatoSolicitud(
                icono: Icons.verified_user_outlined,
                titulo: 'Rol aprobado',
                valor: nombreRolAprobado,
              ),
            ],

            const SizedBox(height: 10),

            _DatoSolicitud(
              icono: Icons.numbers,
              titulo: 'Solicitud',
              valor: '#$idSolicitud',
            ),

            // ==================================================
            // OBSERVACIÓN
            // ==================================================
            if (solicitud['observacion'] != null &&
                solicitud['observacion'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Observación: '
                  '${solicitud['observacion']}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            // ==================================================
            // BOTONES PARA SOLICITUD PENDIENTE
            // ==================================================
            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cargando
                          ? null
                          : () {
                              _rechazarSolicitud(solicitud);
                            },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Rechazar',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cargando
                          ? null
                          : () {
                              _editarRol(solicitud);
                            },
                      icon: const Icon(Icons.edit),
                      label: const Text('Cambiar rol'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cargando
                      ? null
                      : () {
                          _aprobarSolicitud(solicitud);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],

            // ==================================================
            // SOLICITUD APROBADA
            // ==================================================
            if (estado == 'APROBADA') ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Esta solicitud ya fue aprobada.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // SOLICITUD RECHAZADA
            // ==================================================
            if (estado == 'RECHAZADA') ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Esta solicitud fue rechazada.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de acceso'),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
          ? RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),

                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 16),

                        Text(
                          'No hay solicitudes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Las nuevas solicitudes aparecerán aquí.',
                          style: TextStyle(color: Colors.grey),
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
                itemCount: _solicitudes.length,
                itemBuilder: (context, index) {
                  return _buildSolicitud(_solicitudes[index]);
                },
              ),
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
        Icon(icono, size: 20, color: Colors.blue),

        const SizedBox(width: 10),

        Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.w600)),

        Expanded(child: Text(valor)),
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

    switch (estado) {
      case 'APROBADA':
        color = Colors.green;
        break;

      case 'RECHAZADA':
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
