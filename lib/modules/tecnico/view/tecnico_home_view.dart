import 'package:flutter/material.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';
import '../../piso/view/piso_obrero_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import 'solicitudes_obreros_view.dart';
import 'historial_tecnico_view.dart';

class TecnicoHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;

  const TecnicoHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
  });

  @override
  State<TecnicoHomeView> createState() => _TecnicoHomeViewState();
}

class _TecnicoHomeViewState extends State<TecnicoHomeView> {
  final SolicitudObreroController _solicitudController =
      SolicitudObreroController();
  int _conteoPendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarConteo();
  }

  Future<void> _cargarConteo() async {
    try {
      final pendientes =
          await _solicitudController.obtenerSolicitudesPendientes(widget.idObra);
      if (!mounted) return;
      setState(() {
        _conteoPendientes = pendientes.length;
      });
    } catch (_) {
      // Manejar silenciosamente en recargas de segundo plano
    }
  }

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F3FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  color: const Color(0xFF2FA9E0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                        ),
                        if (badge != null && badge > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badge pendiente(s)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C8A93),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF7C8A93),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Cambiar de obra',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
            );
          },
        ),
        title: const Text('Panel del Técnico'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarConteo,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            const Text(
              'Bienvenido, Técnico',
              style: TextStyle(fontSize: 16, color: Color(0xFF7C8A93)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestión de Materiales',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),
            const SizedBox(height: 25),

            // 1. PISOS DE LA OBRA (Igual que en obrero)
            _opcion(
              icono: Icons.layers_outlined,
              titulo: 'Pisos de la obra',
              descripcion:
                  'Consulta los pisos de esta obra y gestiona o solicita material directamente.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PisosObraView(
                      idObra: widget.idObra,
                      idUsuario: widget.idUsuario,
                      idRol: 2, // Rol Técnico
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. SOLICITUDES DE OBREROS (PÁGINA NUEVA DE REVISIÓN)
            _opcion(
              icono: Icons.pending_actions,
              titulo: 'Solicitudes de Materiales',
              descripcion:
                  'Revisa, edita cantidades, aprueba o rechaza los pedidos de material enviados por los obreros.',
              badge: _conteoPendientes,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SolicitudesObrerosView(
                      idObra: widget.idObra,
                      idTecnicoUsuario: widget.idUsuario,
                    ),
                  ),
                );
                _cargarConteo();
              },
            ),

            const SizedBox(height: 16),

            // 3. HISTORIAL DE LA OBRA
            _opcion(
              icono: Icons.history,
              titulo: 'Historial de la Obra',
              descripcion:
                  'Consulta todas las solicitudes procesadas y su estado en esta obra.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialTecnicoView(idObra: widget.idObra),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
