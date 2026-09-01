import 'package:flutter/material.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';
import 'revisar_solicitud_obrero_view.dart';

class SolicitudesObrerosView extends StatefulWidget {
  final int idObra;
  final int idTecnicoUsuario;

  const SolicitudesObrerosView({
    super.key,
    required this.idObra,
    required this.idTecnicoUsuario,
  });

  @override
  State<SolicitudesObrerosView> createState() => _SolicitudesObrerosViewState();
}

class _SolicitudesObrerosViewState extends State<SolicitudesObrerosView> {
  final SolicitudObreroController _controller = SolicitudObreroController();
  List<SolicitudObreroModel> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
    });

    try {
      final list =
          await _controller.obtenerSolicitudesPendientes(widget.idObra);

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
            'Error al cargar solicitudes: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _revisar(SolicitudObreroModel sol) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevisarSolicitudObreroView(
          solicitud: sol,
          idTecnicoUsuario: widget.idTecnicoUsuario,
        ),
      ),
    );

    if (res == true && mounted) {
      _cargarSolicitudes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Solicitudes de Obreros'),
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
                          Icons.task_alt,
                          size: 72,
                          color: Color(0xFFB7C5CC),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay solicitudes pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Todos los pedidos de los obreros han sido revisados y procesados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7C8A93)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudes,
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
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F3FC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pending_actions,
                              color: Color(0xFF2FA9E0),
                            ),
                          ),
                          title: Text(
                            obrero,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$piso • ${sol.detalles.length} ítem(s)',
                                style: const TextStyle(
                                  color: Color(0xFF1D7FAE),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fecha: ${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year} ${sol.fecha.hour.toString().padLeft(2, '0')}:${sol.fecha.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C8A93),
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _revisar(sol),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2FA9E0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Revisar'),
                          ),
                          onTap: () => _revisar(sol),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
