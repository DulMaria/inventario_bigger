// lib/modules/administrador/view/admin_almacen_view.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/obra_model.dart';
import '../../../models/solicitud_model.dart';
import '../../almacen/controller/almacen_controller.dart';
import '../../obra/controller/obra_controller.dart';

class _MaterialStockItem {
  final int idMaterial;
  final String nombre;
  final String codigo;
  int cantidadTotal;

  _MaterialStockItem({
    required this.idMaterial,
    required this.nombre,
    required this.codigo,
    required this.cantidadTotal,
  });
}

class AdminAlmacenView extends StatefulWidget {
  const AdminAlmacenView({super.key});

  @override
  State<AdminAlmacenView> createState() => _AdminAlmacenViewState();
}

class _AdminAlmacenViewState extends State<AdminAlmacenView>
    with SingleTickerProviderStateMixin {
  final AlmacenController _almacenController = AlmacenController();
  final ObraController _obraController = ObraController();

  late TabController _tabController;

  List<ObraModel> _obras = [];
  int? _obraSeleccionadaId;

  List<SolicitudModel> _solicitudesEnAlmacen = [];
  List<SolicitudModel> _solicitudesEntregadas = [];
  bool _cargando = true;

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
    setState(() => _cargando = true);

    try {
      final listaObras = await _obraController.obtenerObras();
      final enAlmacen = await _almacenController.obtenerTodosMaterialesEnAlmacenAdmin(
        idObraFiltro: _obraSeleccionadaId,
      );
      final entregadas = await _almacenController.obtenerTodosMaterialesEntregadosAdmin(
        idObraFiltro: _obraSeleccionadaId,
      );

      if (!mounted) return;

      setState(() {
        _obras = listaObras;
        _solicitudesEnAlmacen = enAlmacen;
        _solicitudesEntregadas = entregadas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar Almacén: $e')),
      );
    }
  }

  List<_MaterialStockItem> get _stockConsolidado {
    final mapa = <int, _MaterialStockItem>{};
    for (final sol in _solicitudesEnAlmacen) {
      for (final det in sol.detalles) {
        final matId = det.material?.idMaterial ?? det.idMaterial ?? 0;
        final nombre = det.material?.nombre ?? 'Material #$matId';
        final codigo = det.material?.codigo ?? '-';
        final cant = det.cantidad;

        if (mapa.containsKey(matId)) {
          mapa[matId]!.cantidadTotal += cant;
        } else {
          mapa[matId] = _MaterialStockItem(
            idMaterial: matId,
            nombre: nombre,
            codigo: codigo,
            cantidadTotal: cant,
          );
        }
      }
    }
    return mapa.values.toList();
  }

  Uint8List? _tryDecodeBase64(String raw) {
    try {
      String cleanData = raw.trim();
      if (cleanData.isEmpty) return null;

      if (cleanData.contains(',')) {
        cleanData = cleanData.substring(cleanData.indexOf(',') + 1);
      } else if (cleanData.startsWith('data:image')) {
        final headerEnd = cleanData.indexOf(';base64');
        if (headerEnd != -1) {
          cleanData = cleanData.substring(headerEnd + 7);
        }
      }

      cleanData = cleanData.replaceAll(RegExp(r'\s+'), '');
      if (cleanData.isEmpty) return null;
      return base64Decode(cleanData);
    } catch (_) {
      return null;
    }
  }

  void _verImagenCompleta(String? url, String titulo) {
    if (url == null || url.isEmpty) return;

    Widget imageWidget;
    if (url.startsWith('data:image')) {
      final bytes = _tryDecodeBase64(url);
      if (bytes != null && bytes.isNotEmpty) {
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } else {
        imageWidget = const Center(
          child: Text('Imagen no disponible', style: TextStyle(color: Colors.white)),
        );
      }
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: imageWidget),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSolicitud(SolicitudModel sol, bool esEntregado) {
    final obraNombre = sol.piso?.obra.nombre ?? 'Obra';
    final pisoNombre = sol.piso?.nombre ?? (sol.piso != null ? 'Piso #${sol.piso!.idPiso}' : 'Piso');
    final fecha = '${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}';
    final totalItems = sol.detalles.length;

    String? fotoProforma;
    for (final d in sol.detalles) {
      if (d.rutaImagen != null && d.rutaImagen!.isNotEmpty) {
        fotoProforma = d.rutaImagen;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      backgroundColor: esEntregado ? Colors.blue.shade50 : Colors.teal.shade50,
                      child: Icon(
                        esEntregado ? Icons.task_alt : Icons.warehouse_rounded,
                        color: esEntregado ? Colors.blue.shade700 : Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitud #${sol.idSolicitud}',
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
                    color: esEntregado ? Colors.blue.shade100 : Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    esEntregado ? 'Entregado' : 'En Almacén',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: esEntregado ? Colors.blue.shade900 : Colors.teal.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('📦 Total Ítems: $totalItems | 📅 Fecha: $fecha',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2A32))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sol.detalles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final det = sol.detalles[idx];
                  final matNombre = det.material?.nombre ?? 'Material #${det.idMaterial ?? idx}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• $matNombre',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'Cant: ${det.cantidad}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (fotoProforma != null && fotoProforma.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _verImagenCompleta(fotoProforma, 'Proforma Autorizada - Solicitud #${sol.idSolicitud}'),
                icon: const Icon(Icons.image, size: 18),
                label: const Text('Ver Foto Proforma Autorizada', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockList = _stockConsolidado;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Almacén y Stock (Global)'),
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
              icon: const Icon(Icons.inventory_2_outlined),
              text: 'Stock (${stockList.length})',
            ),
            Tab(
              icon: const Icon(Icons.warehouse_rounded),
              text: 'En Almacén (${_solicitudesEnAlmacen.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Entregados (${_solicitudesEntregadas.length})',
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
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: STOCK CONSOLIDADO
                      stockList.isEmpty
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
                                        Text('No hay materiales registrados en Almacén',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                                itemCount: stockList.length,
                                itemBuilder: (context, index) {
                                  final item = stockList[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.teal.shade50,
                                        child: Icon(Icons.category, color: Colors.teal.shade700),
                                      ),
                                      title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Código: ${item.codigo}'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Stock: ${item.cantidadTotal}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      // TAB 2: EN ALMACÉN
                      _solicitudesEnAlmacen.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _cargarDatos,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.warehouse_rounded, size: 64, color: Color(0xFFB7C5CC)),
                                        SizedBox(height: 16),
                                        Text('No hay compras en Almacén por entregar',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                                itemCount: _solicitudesEnAlmacen.length,
                                itemBuilder: (_, index) => _buildCardSolicitud(_solicitudesEnAlmacen[index], false),
                              ),
                            ),

                      // TAB 3: ENTREGADOS
                      _solicitudesEntregadas.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _cargarDatos,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.history, size: 64, color: Color(0xFFB7C5CC)),
                                        SizedBox(height: 16),
                                        Text('No hay entregas registradas en el historial',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                                itemCount: _solicitudesEntregadas.length,
                                itemBuilder: (_, index) => _buildCardSolicitud(_solicitudesEntregadas[index], true),
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
