import 'package:flutter/material.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';

class HistorialTecnicoView extends StatefulWidget {
  final int idObra;

  const HistorialTecnicoView({super.key, required this.idObra});

  @override
  State<HistorialTecnicoView> createState() => _HistorialTecnicoViewState();
}

class _HistorialTecnicoViewState extends State<HistorialTecnicoView> {
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
      final list = await _controller.obtenerTodas(widget.idObra);

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
              ? const Center(
                  child: Text('No hay historial de solicitudes en esta obra.'),
                )
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final sol = _solicitudes[index];

                      final obrero = sol.usuario != null
                          ? '${sol.usuario!.nombre} ${sol.usuario!.apellido}'
                          : 'Obrero #${sol.idUsuario}';

                      final piso = sol.piso?.nombre ??
                          'Piso (Nivel ${sol.piso?.numeroPiso ?? ''})';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _fondoEstado(sol.estado),
                            child: Icon(
                              sol.estado == 'APROBADA'
                                  ? Icons.check
                                  : sol.estado == 'RECHAZADA'
                                      ? Icons.close
                                      : Icons.access_time,
                              color: _colorEstado(sol.estado),
                            ),
                          ),
                          title: Text(
                            '$obrero • $piso',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Estado: ${sol.estado} • ${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}',
                            style: TextStyle(
                              color: _colorEstado(sol.estado),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const Text(
                                    'Materiales:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  ...sol.detalles.map((d) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(d.material?.nombre ?? 'Material'),
                                          Text(
                                            'Cant: ${d.cantidad}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (sol.observacion != null &&
                                      sol.observacion!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Observación: ${sol.observacion}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF7C8A93),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
