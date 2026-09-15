// lib/modules/almacen/view/almacen_home_view.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/solicitud_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import '../controller/almacen_controller.dart';

class AlmacenHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;

  const AlmacenHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<AlmacenHomeView> createState() => _AlmacenHomeViewState();
}

class _AlmacenHomeViewState extends State<AlmacenHomeView> with SingleTickerProviderStateMixin {
  final AlmacenController _almacenController = AlmacenController();
  final AuthController _authController = AuthController();

  late TabController _tabController;
  bool _cargando = true;
  bool _procesando = false;

  List<SolicitudModel> _solicitudesEnAlmacen = [];
  List<SolicitudModel> _solicitudesEntregadas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final enAlmacen = await _almacenController.obtenerMaterialesEnAlmacen(widget.idObra);
      final entregadas = await _almacenController.obtenerMaterialesEntregados(widget.idObra);

      if (!mounted) return;
      setState(() {
        _solicitudesEnAlmacen = enAlmacen;
        _solicitudesEntregadas = entregadas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de Almacén: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // DECODIFICADOR SEGURO DE FOTOS BASE64 / STORAGE
  // ============================================================
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

  Widget _buildAdaptiveImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url == null || url.isEmpty) {
      return Container(
        width: width,
        height: height ?? 120,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (url.startsWith('data:image')) {
      final bytes = _tryDecodeBase64(url);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height ?? 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      }
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height ?? 120,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
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

  // ============================================================
  // CONFIRMAR DESPACHO / ENTREGA A OBRERO
  // ============================================================
  Future<void> _confirmarDespacho(SolicitudModel sol) async {
    final observacionController = TextEditingController();
    bool aceptoEntrega = false;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping, color: Colors.blue.shade800, size: 28),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Despachar Material a Obrero',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade900, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Confirmarás que la Solicitud #${sol.idSolicitud} fue entregada físicamente al personal en obra.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Solicitante: ${sol.usuario?.nombreCompleto ?? "Obrero"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2A47)),
                ),
                Text(
                  'Piso: ${sol.piso?.nombre ?? "Piso General"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Materiales a Entregar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2A47)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sol.detalles.map((d) {
                      final matNombre = d.material?.nombre ?? 'Material #${d.idMaterial}';
                      final cant = d.cantidad;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $matNombre: $cant unid.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: observacionController,
                  decoration: const InputDecoration(
                    labelText: 'Observación de Entrega / Firma (Opcional)',
                    hintText: 'Ej. Entregado a capataz de piso 2',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setModalState(() {
                      aceptoEntrega = !aceptoEntrega;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: aceptoEntrega,
                        onChanged: (val) {
                          setModalState(() {
                            aceptoEntrega = val ?? false;
                          });
                        },
                        activeColor: Colors.blue.shade700,
                      ),
                      const Expanded(
                        child: Text(
                          'Confirmo la entrega física de los materiales en Almacén.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: aceptoEntrega ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Confirmar Despacho'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) {
      observacionController.dispose();
      return;
    }

    setState(() => _procesando = true);

    try {
      final notas = observacionController.text.trim();
      await _almacenController.marcarComoEntregado(
        idSolicitud: sol.idSolicitud,
        idUsuarioAlmacen: widget.idUsuario,
        observacion: notas.isNotEmpty ? notas : 'Material despachado por Almacén',
      );

      observacionController.dispose();
      await _cargarDatos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Solicitud #${sol.idSolicitud} marcada como ENTREGADA.'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      observacionController.dispose();
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al despachar material: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // NAVEGACIÓN Y CERRAR SESIÓN
  // ============================================================
  Future<void> _cambiarObra() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del sistema?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _authController.cerrarSesion();
      if (!mounted) return;
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Almacén e Inventario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.nombreObra ?? 'Obra',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B2A47),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar Datos',
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Cambiar de Obra',
            onPressed: _cambiarObra,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_solicitudesEnAlmacen.length}'),
                backgroundColor: const Color(0xFF10B981),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              text: 'En Almacén',
            ),
            Tab(
              icon: Badge(
                label: Text('${_solicitudesEntregadas.length}'),
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.history_outlined),
              ),
              text: 'Historial de Entregas',
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2A47)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabEnAlmacen(),
                _buildTabHistorial(),
              ],
            ),
    );
  }

  // ============================================================
  // TAB 1: EN ALMACÉN (COMPRADOS LISTOS PARA ENTREGAR)
  // ============================================================
  Widget _buildTabEnAlmacen() {
    if (_solicitudesEnAlmacen.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay materiales pendientes de entrega en Almacén',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
            ),
            const SizedBox(height: 8),
            Text(
              'Las nuevas compras autorizadas aparecerán aquí automáticamente en cuanto el comprador confirme su adquisición.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudesEnAlmacen.length,
        itemBuilder: (context, index) {
          final sol = _solicitudesEnAlmacen[index];
          final pisoNombre = sol.piso?.nombre ?? (sol.piso != null ? 'Piso #${sol.piso!.idPiso}' : 'Piso General');
          final fecha = '${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}';
          final obrero = sol.usuario?.nombreCompleto ?? 'Solicitante';

          // Buscar imágenes asociadas
          final fotosDetalles = sol.detalles
              .where((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty)
              .map((d) => d.rutaImagen!)
              .toSet()
              .toList();

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.warehouse_rounded, color: Colors.green.shade700, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solicitud #${sol.idSolicitud}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
                              ),
                              Text(
                                '$pisoNombre • $fecha',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'EN ALMACÉN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Solicitado por: $obrero',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  if (sol.observacion != null && sol.observacion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sol.observacion!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Text(
                    'Materiales a Entregar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2A47)),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: sol.detalles.map((d) {
                        final matNombre = d.material?.nombre ?? 'Material #${d.idMaterial}';
                        final cant = d.cantidad;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(matNombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$cant unid.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  if (fotosDetalles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotosDetalles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, fIdx) {
                          final url = fotosDetalles[fIdx];
                          return GestureDetector(
                            onTap: () => _verImagenCompleta(url, 'Comprobante Solicitud #${sol.idSolicitud}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildAdaptiveImage(url, width: 90, height: 100),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _procesando ? null : () => _confirmarDespacho(sol),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 20),
                      label: const Text(
                        'Despachar / Entregar a Obrero',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TAB 2: HISTORIAL DE ENTREGAS (ESTADO: ENTREGADO)
  // ============================================================
  Widget _buildTabHistorial() {
    if (_solicitudesEntregadas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay despachos registrados en el historial.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudesEntregadas.length,
      itemBuilder: (context, index) {
        final sol = _solicitudesEntregadas[index];
        final pisoNombre = sol.piso?.nombre ?? (sol.piso != null ? 'Piso #${sol.piso!.idPiso}' : 'Piso General');
        final fecha = '${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}';
        final obrero = sol.usuario?.nombreCompleto ?? 'Obrero';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.check_circle, color: Colors.blue.shade800, size: 22),
            ),
            title: Text('Solicitud #${sol.idSolicitud} • $pisoNombre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Entregado a: $obrero • $fecha\n${sol.observacion ?? ""}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
