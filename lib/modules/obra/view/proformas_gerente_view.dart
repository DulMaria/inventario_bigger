// lib/modules/obra/view/proformas_gerente_view.dart
import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/solicitud_model.dart';
import '../../compras/controller/compras_controller.dart';
import 'revisar_proformas_view.dart';

class ProformasGerenteView extends StatefulWidget {
  final int idObra;
  final int idUsuarioGerente;
  final String? nombreObra;
  final bool isEmbedded;

  const ProformasGerenteView({
    super.key,
    required this.idObra,
    required this.idUsuarioGerente,
    this.nombreObra,
    this.isEmbedded = false,
  });

  @override
  State<ProformasGerenteView> createState() => _ProformasGerenteViewState();
}

class _ProformasGerenteViewState extends State<ProformasGerenteView> {
  final ComprasController _comprasController = ComprasController();

  List<SolicitudModel> _solicitudesEnviadas = [];
  List<SolicitudModel> _solicitudesAprobadas = [];
  List<SolicitudModel> _solicitudesCompradas = [];
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
      final compradas = await _comprasController.obtenerSolicitudesCompradas(widget.idObra);

      if (!mounted) return;

      setState(() {
        _solicitudesEnviadas = enviadas;
        _solicitudesAprobadas = aprobadas;
        _solicitudesCompradas = compradas;
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

  Widget _buildCard(SolicitudModel s, int estadoTipo) {
    final pisoNombre = s.piso?.nombre ?? (s.piso != null ? 'Piso #${s.piso!.idPiso}' : 'Piso');
    final fecha = '${s.fecha.day}/${s.fecha.month}/${s.fecha.year}';
    final totalItems = s.detalles.length;

    Color badgeBg;
    Color badgeFg;
    IconData iconData;
    String badgeText;
    String actionText;

    if (estadoTipo == 0) {
      badgeBg = Colors.amber.shade100;
      badgeFg = Colors.amber.shade900;
      iconData = Icons.pending_actions;
      badgeText = 'Pendiente Decisión';
      actionText = 'Revisar fotos de proformas y autorizar ➔';
    } else if (estadoTipo == 1) {
      badgeBg = Colors.green.shade100;
      badgeFg = Colors.green.shade900;
      iconData = Icons.verified;
      badgeText = 'Autorizada / A Comprar';
      actionText = 'Ver proforma autorizada ➔';
    } else {
      badgeBg = Colors.blue.shade100;
      badgeFg = Colors.blue.shade900;
      iconData = Icons.shopping_bag_outlined;
      badgeText = 'Comprado / En Almacén';
      actionText = 'Ver proforma y compra realizada ➔';
    }

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
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: badgeBg,
                          child: Icon(
                            iconData,
                            color: badgeFg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
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
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📦 $totalItems materiales', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('📅 $fecha', style: const TextStyle(fontSize: 12, color: Color(0xFF7C8A93))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: badgeFg,
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
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: widget.isEmbedded 
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: AppBar(
                  backgroundColor: const Color(0xFF1B2A47),
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  elevation: 0,
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
                        text: 'A Comprar (${_solicitudesAprobadas.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        text: 'Comprados (${_solicitudesCompradas.length})',
                      ),
                    ],
                  ),
                ),
              )
            : AppBar(
                title: Text(widget.nombreObra != null ? 'Proformas - ${widget.nombreObra}' : 'Proformas de Materiales'),
                backgroundColor: const Color(0xFF1B2A47),
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
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
                      text: 'A Comprar (${_solicitudesAprobadas.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      text: 'Comprados (${_solicitudesCompradas.length})',
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
                            itemBuilder: (_, index) => _buildCard(_solicitudesEnviadas[index], 0),
                          ),
                        ),

                  // Tab 2: Autorizadas / A comprar
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
                            itemBuilder: (_, index) => _buildCard(_solicitudesAprobadas[index], 1),
                          ),
                        ),

                  // Tab 3: Comprados / En almacén
                  _solicitudesCompradas.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFB7C5CC)),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay compras registradas en Almacén',
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
                            itemCount: _solicitudesCompradas.length,
                            itemBuilder: (_, index) => _buildCard(_solicitudesCompradas[index], 2),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
