// lib/modules/administrador/view/admin_proformas_view.dart
import 'package:flutter/material.dart';
import '../../../models/obra_model.dart';
import '../../../models/solicitud_model.dart';
import '../../compras/controller/compras_controller.dart';
import '../../obra/controller/obra_controller.dart';
import '../../obra/view/revisar_proformas_view.dart';
import '../../auth/controller/auth_controller.dart';

class AdminProformasView extends StatefulWidget {
  const AdminProformasView({super.key});

  @override
  State<AdminProformasView> createState() => _AdminProformasViewState();
}

class _AdminProformasViewState extends State<AdminProformasView>
    with SingleTickerProviderStateMixin {
  final ComprasController _comprasController = ComprasController();
  final ObraController _obraController = ObraController();
  final AuthController _authController = AuthController();

  late TabController _tabController;

  List<ObraModel> _obras = [];
  int? _obraSeleccionadaId;

  List<SolicitudModel> _todasLasSolicitudes = [];
  bool _cargando = true;
  int _idAdmin = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final userActualId = await _authController.obtenerIdUsuario() ?? 0;
      final listaObras = await _obraController.obtenerObras();
      final solicitudes = await _comprasController.obtenerTodasLasSolicitudesAdmin(
        idObraFiltro: _obraSeleccionadaId,
      );

      if (!mounted) return;

      setState(() {
        _idAdmin = userActualId;
        _obras = listaObras;
        _todasLasSolicitudes = solicitudes;
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

  List<SolicitudModel> get _solicitudesACotizar => _todasLasSolicitudes
      .where((s) =>
          s.estado == 'PENDIENTE' &&
          !s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty) &&
          !(s.observacion?.contains('[COTIZACIONES_ENVIADAS]') ?? false) &&
          !(s.observacion?.contains('[PROFORMAS:') ?? false))
      .toList();

  List<SolicitudModel> get _solicitudesEnviadas => _todasLasSolicitudes
      .where((s) =>
          s.estado == 'PENDIENTE' &&
          (s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty) ||
              (s.observacion?.contains('[COTIZACIONES_ENVIADAS]') ?? false) ||
              (s.observacion?.contains('[PROFORMAS:') ?? false)))
      .toList();

  List<SolicitudModel> get _solicitudesAprobadas => _todasLasSolicitudes
      .where((s) => s.estado == 'APROBADA')
      .toList();

  Widget _buildCard(SolicitudModel s, int tipoTab) {
    final obraNombre = s.piso?.obra.nombre ?? 'Obra';
    final pisoNombre = s.piso?.nombre ?? (s.piso != null ? 'Piso #${s.piso!.idPiso}' : 'Piso');
    final fecha = '${s.fecha.day}/${s.fecha.month}/${s.fecha.year}';
    final totalItems = s.detalles.length;

    Color badgeColor;
    String badgeText;

    if (tipoTab == 0) {
      badgeColor = Colors.orange;
      badgeText = 'A Cotizar';
    } else if (tipoTab == 1) {
      badgeColor = Colors.blue;
      badgeText = 'En Revisión';
    } else {
      badgeColor = Colors.green;
      badgeText = 'Autorizada';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RevisarProformasView(
                solicitud: s,
                idUsuarioGerente: _idAdmin,
                nombreObra: obraNombre,
                esAdmin: true,
              ),
            ),
          );
          if (res == true) {
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
                        backgroundColor: const Color(0xFFE1F3FC),
                        child: Icon(
                          tipoTab == 0
                              ? Icons.request_quote
                              : tipoTab == 1
                                  ? Icons.hourglass_top
                                  : Icons.verified,
                          color: const Color(0xFF2FA9E0),
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
                            '🏗️ $obraNombre - $pisoNombre',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📦 $totalItems materiales solicitados', style: const TextStyle(fontSize: 13)),
                  Text('📅 $fecha', style: const TextStyle(fontSize: 12, color: Color(0xFF7C8A93))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalle y proformas ➔',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
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

  Widget _buildList(List<SolicitudModel> lista, int tipoTab, String textoVacio) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: const Color(0xFFB7C5CC)),
                  const SizedBox(height: 16),
                  Text(
                    textoVacio,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2A32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (_, index) => _buildCard(lista[index], tipoTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Cotizaciones y Proformas (Global)'),
        backgroundColor: Colors.blue[700],
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
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.request_quote),
              text: 'A Cotizar (${_solicitudesACotizar.length})',
            ),
            Tab(
              icon: const Icon(Icons.hourglass_top),
              text: 'En Revisión (${_solicitudesEnviadas.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Autorizadas (${_solicitudesAprobadas.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de Obra
          if (_obras.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Text('Obra:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _obraSeleccionadaId,
                        isExpanded: true,
                        hint: const Text('Todas las obras'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('🌐 Todas las obras', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._obras.map((o) {
                            return DropdownMenuItem<int?>(
                              value: o.idObra,
                              child: Text(o.nombre),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _obraSeleccionadaId = val;
                          });
                          _cargarDatos();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_solicitudesACotizar, 0, 'No hay solicitudes pendientes de cotización'),
                _buildList(_solicitudesEnviadas, 1, 'No hay cotizaciones enviadas a revisión'),
                _buildList(_solicitudesAprobadas, 2, 'No hay cotizaciones autorizadas'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
