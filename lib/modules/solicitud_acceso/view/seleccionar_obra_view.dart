import 'package:flutter/material.dart';

import '../../../models/obra_model.dart';
import '../../../models/solicitud_acceso_model.dart';

import '../controller/solicitud_acceso_controller.dart';

import 'seleccionar_rol_view.dart';

// IMPORTA TUS HOMES
import '../../usuario/view/obrero_home_view.dart';
import '../../obra/view/gerente_home_view.dart';

class SeleccionarObraView extends StatefulWidget {
  const SeleccionarObraView({super.key});

  @override
  State<SeleccionarObraView> createState() => _SeleccionarObraViewState();
}

class _SeleccionarObraViewState extends State<SeleccionarObraView> {
  final SolicitudAccesoController _controller = SolicitudAccesoController();

  List<ObraModel> _obras = [];

  List<ObraModel> _misObras = [];

  List<SolicitudAccesoModel> _misSolicitudes = [];

  ObraModel? _obraSeleccionada;

  bool _cargando = true;

  bool _entrando = false;

  @override
  void initState() {
    super.initState();

    _cargarDatos();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final obrasDisponibles = await _controller.obtenerObrasDisponibles();

      final misObras = await _controller.obtenerMisObras();

      final misSolicitudes = await _controller.obtenerMisSolicitudes();

      if (!mounted) {
        return;
      }

      final Map<int, ObraModel> todasLasObras = {};

      // Obras donde ya pertenece
      for (final obra in misObras) {
        todasLasObras[obra.idObra] = obra;
      }

      // Obras disponibles para solicitar
      for (final obra in obrasDisponibles) {
        todasLasObras[obra.idObra] = obra;
      }

      setState(() {
        _obras = todasLasObras.values.toList();

        _misObras = misObras;

        _misSolicitudes = misSolicitudes;

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

  // ============================================================
  // VERIFICAR ACCESO
  // ============================================================

  bool _tieneAcceso(int idObra) {
    return _misObras.any((obra) => obra.idObra == idObra);
  }

  // ============================================================
  // VERIFICAR SOLICITUD PENDIENTE
  // ============================================================

  bool _tieneSolicitudPendiente(int idObra) {
    return _misSolicitudes.any(
      (solicitud) =>
          solicitud.idObra == idObra && solicitud.estado == 'PENDIENTE',
    );
  }

  // ============================================================
  // CONTINUAR
  // ============================================================

  Future<void> _continuar() async {
    if (_obraSeleccionada == null) {
      _mostrarMensaje('Selecciona una obra para continuar');

      return;
    }

    if (_entrando) {
      return;
    }

    final idObra = _obraSeleccionada!.idObra;

    // ==========================================================
    // SI YA TIENE ACCESO
    // ==========================================================

    if (_tieneAcceso(idObra)) {
      setState(() {
        _entrando = true;
      });

      try {
        final rol = await _controller.obtenerRolEnObra(idObra);

        if (!mounted) {
          return;
        }

        if (rol == null) {
          _mostrarMensaje('No se encontró un rol asignado para esta obra.');

          return;
        }

        await _entrarSegunRol(rol: rol, idObra: idObra);
      } catch (e) {
        if (!mounted) {
          return;
        }

        _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) {
          setState(() {
            _entrando = false;
          });
        }
      }

      return;
    }

    // ==========================================================
    // SI TIENE SOLICITUD PENDIENTE
    // ==========================================================

    if (_tieneSolicitudPendiente(idObra)) {
      _mostrarMensaje('Ya tienes una solicitud pendiente para esta obra.');

      return;
    }

    // ==========================================================
    // SI NO TIENE ACCESO
    // ==========================================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarRolView(obra: _obraSeleccionada!),
      ),
    );

    // Actualizar al regresar
    if (mounted) {
      _cargarDatos();
    }
  }

  // ============================================================
  // ENTRAR SEGÚN ROL
  // ============================================================

  Future<void> _entrarSegunRol({required int rol, required int idObra}) async {
    switch (rol) {
      // ========================================================
      // OBRERO
      // ========================================================
      case 1:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ObreroHomeView()),
        );
        break;

      // ========================================================
      // TÉCNICO
      // ========================================================
      case 2:
        _mostrarMensaje('Rol Técnico detectado. Falta conectar su Home.');
        break;

      // ========================================================
      // GERENTE
      // ========================================================
      case 3:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GerenteHomeView()),
        );
        break;

      // ========================================================
      // COMPRAS
      // ========================================================
      case 4:
        _mostrarMensaje('Rol Compras detectado. Falta conectar su Home.');
        break;

      // ========================================================
      // ALMACÉN
      // ========================================================
      case 5:
        _mostrarMensaje('Rol Almacén detectado. Falta conectar su Home.');
        break;

      // ========================================================
      // SUPERVISOR
      // ========================================================
      case 6:
        _mostrarMensaje('Rol Supervisor detectado. Falta conectar su Home.');
        break;

      // ========================================================
      // ROL DESCONOCIDO
      // ========================================================
      default:
        _mostrarMensaje('El rol asignado no es válido.');
    }
  }

  // ============================================================
  // MENSAJE
  // ============================================================

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

  // ============================================================
  // ESTADO
  // ============================================================

  String _estadoObra(int idObra) {
    if (_tieneAcceso(idObra)) {
      return 'Ya tienes acceso';
    }

    if (_tieneSolicitudPendiente(idObra)) {
      return 'Solicitud pendiente';
    }

    return 'Solicitar acceso';
  }

  // ============================================================
  // COLOR ESTADO
  // ============================================================

  Color _colorEstado(int idObra) {
    if (_tieneAcceso(idObra)) {
      return Colors.green;
    }

    if (_tieneSolicitudPendiente(idObra)) {
      return Colors.orange;
    }

    return const Color(0xFF2FA9E0);
  }

  // ============================================================
  // ICONO ESTADO
  // ============================================================

  IconData _iconoEstado(int idObra) {
    if (_tieneAcceso(idObra)) {
      return Icons.check_circle;
    }

    if (_tieneSolicitudPendiente(idObra)) {
      return Icons.access_time;
    }

    return Icons.add_circle_outline;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),

      appBar: AppBar(
        title: const Text('Seleccionar obra'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),

      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _obras.isEmpty
          ? _sinObras()
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Selecciona una obra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2A32),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Puedes ingresar a las obras donde ya tienes acceso o solicitar acceso a una nueva obra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarDatos,

                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),

                      itemCount: _obras.length,

                      itemBuilder: (context, index) {
                        final obra = _obras[index];

                        final seleccionada =
                            _obraSeleccionada?.idObra == obra.idObra;

                        final tieneAcceso = _tieneAcceso(obra.idObra);

                        final pendiente = _tieneSolicitudPendiente(obra.idObra);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),

                          elevation: seleccionada ? 3 : 1,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),

                            side: BorderSide(
                              color: seleccionada
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
                              backgroundColor: tieneAcceso
                                  ? Colors.green.shade100
                                  : pendiente
                                  ? Colors.orange.shade100
                                  : const Color(0xFFE1F3FC),

                              child: Icon(
                                Icons.business,

                                color: tieneAcceso
                                    ? Colors.green
                                    : pendiente
                                    ? Colors.orange
                                    : const Color(0xFF2FA9E0),
                              ),
                            ),

                            title: Text(
                              obra.nombre,

                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(obra.direccion ?? 'Sin dirección'),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      Icon(
                                        _iconoEstado(obra.idObra),
                                        size: 16,
                                        color: _colorEstado(obra.idObra),
                                      ),

                                      const SizedBox(width: 5),

                                      Text(
                                        _estadoObra(obra.idObra),

                                        style: TextStyle(
                                          color: _colorEstado(obra.idObra),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            trailing: Radio<int>(
                              value: obra.idObra,

                              groupValue: _obraSeleccionada?.idObra,

                              activeColor: const Color(0xFF2FA9E0),

                              onChanged: _entrando
                                  ? null
                                  : (_) {
                                      setState(() {
                                        _obraSeleccionada = obra;
                                      });
                                    },
                            ),

                            onTap: _entrando
                                ? null
                                : () {
                                    setState(() {
                                      _obraSeleccionada = obra;
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

                  color: Colors.white,

                  child: SizedBox(
                    width: double.infinity,

                    height: 52,

                    child: ElevatedButton(
                      onPressed: _obraSeleccionada == null || _entrando
                          ? null
                          : _continuar,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA9E0),

                        foregroundColor: Colors.white,

                        disabledBackgroundColor: Colors.grey.shade300,

                        disabledForegroundColor: Colors.grey.shade600,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: _entrando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continuar',

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

  // ============================================================
  // SIN OBRAS
  // ============================================================

  Widget _sinObras() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.business_outlined,
              size: 70,
              color: Color(0xFF2FA9E0),
            ),

            const SizedBox(height: 20),

            const Text(
              'No hay obras disponibles',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'No existen obras disponibles en este momento.',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _cargarDatos,

              icon: const Icon(Icons.refresh),

              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
