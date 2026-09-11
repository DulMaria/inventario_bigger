// lib/modules/obra/view/proformas_gerente_view.dart
import 'package:flutter/material.dart';
import '../../../models/solicitud_model.dart';
import '../../compras/controller/compras_controller.dart';
import 'revisar_proformas_view.dart';

class ProformasGerenteView extends StatefulWidget {
  final int idObra;
  final int idUsuarioGerente;
  final String? nombreObra;

  const ProformasGerenteView({
    super.key,
    required this.idObra,
    required this.idUsuarioGerente,
    this.nombreObra,
  });

  @override
  State<ProformasGerenteView> createState() => _ProformasGerenteViewState();
}

class _ProformasGerenteViewState extends State<ProformasGerenteView> {
  final ComprasController _comprasController = ComprasController();

  List<SolicitudModel> _solicitudesEnviadas = [];
  List<SolicitudModel> _solicitudesAprobadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final enviadas = await _comprasController.obtenerSolicitudesEnviadasAGerente(widget.idObra);
      final aprobadas = await _comprasController.obtenerSolicitudesAprobadas(widget.idObra);

      if (!mounted) return;

      setState(() {
        _solicitudesEnviadas = enviadas;
        _solicitudesAprobadas = aprobadas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar proformas: $e')),
      );
    }
  }

  Widget _buildCard(SolicitudModel s, bool esPendiente) {
    final pisoNombre = s.piso?.nombre ?? (s.piso != null ? 'Piso #${s.piso!.idPiso}' : 'Piso');
    final fecha = '${s.fecha.day}/${s.fecha.month}/${s.fecha.year}';
    final totalItems = s.detalles.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RevisarProformasView(
                solicitud: s,
                idUsuarioGerente: widget.idUsuarioGerente,
                nombreObra: widget.nombreObra,
              ),
            ),
          );
          if (resultado == true) {
            _cargarDatos();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: esPendiente ? Colors.amber.shade50 : Colors.green.shade50,
                        child: Icon(
                          esPendiente ? Icons.pending_actions : Icons.verified,
                          color: esPendiente ? Colors.amber.shade800 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitud #${s.idSolicitud}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Piso: $pisoNombre',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: esPendiente ? Colors.amber.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      esPendiente ? 'Pendiente Decisión' : 'Autorizada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: esPendiente ? Colors.amber.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📦 $totalItems materiales a comprar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('📅 $fecha', style: const TextStyle(fontSize: 12, color: Color(0xFF7C8A93))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    esPendiente ? 'Revisar fotos de proformas y autorizar ➔' : 'Ver proforma autorizada ➔',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: esPendiente ? const Color(0xFF2FA9E0) : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FAFE),
        appBar: AppBar(
          title: Text(widget.nombreObra != null ? 'Proformas - ${widget.nombreObra}' : 'Proformas de Materiales'),
          backgroundColor: const Color(0xFF2FA9E0),
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
              onPressed: _cargarDatos,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.hourglass_empty),
                text: 'Por Autorizar (${_solicitudesEnviadas.length})',
              ),
              Tab(
                icon: const Icon(Icons.check_circle_outline),
                text: 'Autorizadas (${_solicitudesAprobadas.length})',
              ),
            ],
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Por autorizar
                  _solicitudesEnviadas.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFB7C5CC)),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay proformas pendientes de autorización',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2A32)),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Cuando el Encargado de Compras suba cotizaciones, aparecerán aquí.',
                                      style: TextStyle(color: Color(0xFF7C8A93), fontSize: 13),
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
                            itemCount: _solicitudesEnviadas.length,
                            itemBuilder: (_, index) => _buildCard(_solicitudesEnviadas[index], true),
                          ),
                        ),

                  // Tab 2: Autorizadas
                  _solicitudesAprobadas.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 64, color: Color(0xFFB7C5CC)),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay cotizaciones autorizadas todavía',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2A32)),
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
                            itemCount: _solicitudesAprobadas.length,
                            itemBuilder: (_, index) => _buildCard(_solicitudesAprobadas[index], false),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
