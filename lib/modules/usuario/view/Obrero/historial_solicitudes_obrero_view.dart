import 'package:flutter/material.dart';
import '../../../../models/solicitud_obrero_model.dart';
import '../../../solicitud/controller/solicitud_obrero_controller.dart';

class HistorialSolicitudesObreroView extends StatefulWidget {
  final int idObra;
  final int idUsuario;

  const HistorialSolicitudesObreroView({
    super.key,
    required this.idObra,
    required this.idUsuario,
  });

  @override
  State<HistorialSolicitudesObreroView> createState() =>
      _HistorialSolicitudesObreroViewState();
}

class _HistorialSolicitudesObreroViewState
    extends State<HistorialSolicitudesObreroView> {
  final SolicitudObreroController _controller = SolicitudObreroController();
  List<SolicitudObreroModel> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
    });

    try {
      final list = await _controller.obtenerMisSolicitudes(
        idUsuario: widget.idUsuario,
        idObra: widget.idObra,
      );

      if (!mounted) return;

      setState(() {
        _solicitudes = list;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar historial: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
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
      case 'PENDIENTE_REVISION':
        return 'Pendiente de Revisión Técnica';
      case 'APROBADA':
        return 'Aprobada por Técnico';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Historial de Solicitudes'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history_toggle_off,
                          size: 72,
                          color: Color(0xFFB7C5CC),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes solicitudes enviadas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Las solicitudes de materiales que envíes para revisión del técnico aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7C8A93)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final sol = _solicitudes[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecera: Piso y Estado
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sol.piso?.nombre ??
                                          'Piso (Nivel ${sol.piso?.numeroPiso ?? ''})',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E2A32),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _fondoEstado(sol.estado),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _colorEstado(sol.estado)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _textoEstado(sol.estado),
                                      style: TextStyle(
                                        color: _colorEstado(sol.estado),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fecha: ${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year} ${sol.fecha.hour.toString().padLeft(2, '0')}:${sol.fecha.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7C8A93),
                                ),
                              ),
                              const Divider(height: 20),
                              const Text(
                                'Materiales solicitados:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E2A32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...sol.detalles.map((d) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3),
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                              }),
                              if (sol.observacion != null &&
                                  sol.observacion!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: sol.estado == 'RECHAZADA'
                                        ? Colors.red.shade50
                                        : const Color(0xFFF4FAFE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: sol.estado == 'RECHAZADA'
                                          ? Colors.red.shade200
                                          : const Color(0xFF2FA9E0)
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Observación del Técnico: ${sol.observacion}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: sol.estado == 'RECHAZADA'
                                          ? Colors.red.shade900
                                          : const Color(0xFF1D7FAE),
                                      fontStyle: FontStyle.italic,
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
                ),
    );
  }
}
