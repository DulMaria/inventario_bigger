import 'package:flutter/material.dart';

import '../../../models/obra_model.dart';
import '../controller/solicitud_acceso_controller.dart';

class SeleccionarRolView extends StatefulWidget {
  final ObraModel obra;

  const SeleccionarRolView({super.key, required this.obra});

  @override
  State<SeleccionarRolView> createState() => _SeleccionarRolViewState();
}

class _SeleccionarRolViewState extends State<SeleccionarRolView> {
  final SolicitudAccesoController _controller = SolicitudAccesoController();

  List<Map<String, dynamic>> _roles = [];

  int? _rolSeleccionado;

  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    setState(() {
      _cargando = true;
    });

    try {
      final roles = await _controller.obtenerRoles();

      if (!mounted) {
        return;
      }

      setState(() {
        _roles = roles;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
      });

      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _enviarSolicitud() async {
    if (_rolSeleccionado == null) {
      _mostrarMensaje('Selecciona un rol para continuar');
      return;
    }

    setState(() {
      _enviando = true;
    });

    final mensaje = await _controller.solicitarAcceso(
      idObra: widget.obra.idObra,
      idRolSolicitado: _rolSeleccionado!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _enviando = false;
    });

    if (mensaje != null) {
      _mostrarMensaje(mensaje);
      return;
    }

    _mostrarMensaje(
      'Solicitud enviada correctamente. Espera la aprobación del gerente.',
    );

    Navigator.pop(context, true);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D7FAE),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _iconoRol(String nombre) {
    switch (nombre.toUpperCase()) {
      case 'OBRERO':
        return Icons.engineering_outlined;

      case 'TECNICO':
        return Icons.construction_outlined;

      case 'GERENTE':
        return Icons.manage_accounts_outlined;

      case 'COMPRAS':
        return Icons.shopping_cart_outlined;

      case 'ALMACEN':
        return Icons.inventory_2_outlined;

      case 'SUPERVISOR':
        return Icons.supervisor_account_outlined;

      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Seleccionar rol'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
          ? _sinRoles()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    children: [
                      const Text(
                        'Solicitud de acceso',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.obra.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2FA9E0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.obra.direccion ?? 'Sin dirección',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7C8A93),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Selecciona el rol que deseas solicitar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF5F6B73),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final rol = _roles[index];

                      final idRol = rol['id_rol'] as int;
                      final nombreRol = rol['nombre'] as String;

                      final seleccionado = _rolSeleccionado == idRol;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: seleccionado ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: seleccionado
                                ? const Color(0xFF2FA9E0)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: seleccionado
                                ? const Color(0xFF2FA9E0)
                                : const Color(0xFFE1F3FC),
                            child: Icon(
                              _iconoRol(nombreRol),
                              color: seleccionado
                                  ? Colors.white
                                  : const Color(0xFF2FA9E0),
                            ),
                          ),
                          title: Text(
                            nombreRol,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Radio<int>(
                            value: idRol,
                            groupValue: _rolSeleccionado,
                            activeColor: const Color(0xFF2FA9E0),
                            onChanged: (valor) {
                              setState(() {
                                _rolSeleccionado = valor;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _rolSeleccionado = idRol;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviarSolicitud,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA9E0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Enviar solicitud',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sinRoles() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 70,
              color: Color(0xFF2FA9E0),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay roles disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No se encontraron roles configurados para solicitar acceso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _cargarRoles,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
