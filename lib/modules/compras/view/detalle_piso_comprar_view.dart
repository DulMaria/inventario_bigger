// lib/modules/compras/view/detalle_piso_comprar_view.dart
import 'package:flutter/material.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';

class DetallePisoComprarView extends StatefulWidget {
  final String nombrePiso;
  final List<SolicitudModel> solicitudes;
  final int idUsuario;
  final String? nombreObra;

  const DetallePisoComprarView({
    super.key,
    required this.nombrePiso,
    required this.solicitudes,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<DetallePisoComprarView> createState() => _DetallePisoComprarViewState();
}

class _DetallePisoComprarViewState extends State<DetallePisoComprarView> {
  final ComprasController _comprasController = ComprasController();

  final Map<int, List<CotizacionModel>> _cotizacionesPorSolicitud = {};
  bool _cargandoCotizaciones = true;

  @override
  void initState() {
    super.initState();
    _cargarCotizaciones();
  }

  Future<void> _cargarCotizaciones() async {
    setState(() => _cargandoCotizaciones = true);
    try {
      for (final sol in widget.solicitudes) {
        final cotiz = await _comprasController.obtenerCotizacionesPorSolicitud(sol.idSolicitud);
        _cotizacionesPorSolicitud[sol.idSolicitud] = cotiz;
      }
      if (mounted) {
        setState(() => _cargandoCotizaciones = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoCotizaciones = false);
      }
    }
  }

  void _verImagenCompleta(String? url, String titulo) {
    if (url == null || url.isEmpty) return;
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
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Error al cargar la imagen', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    final materialesConsolidados = ExcelExporter.consolidarMateriales(widget.solicitudes);
    final totalMaterialesSumados = materialesConsolidados.fold<int>(0, (sum, m) => sum + m.cantidadTotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.nombrePiso} - Compras',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.nombreObra != null)
              Text(
                widget.nombreObra!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1B2A47),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // BANNER INFORMATIVO
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B2A47), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compras Autorizadas por Gerente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${materialesConsolidados.length} materiales listos • $totalMaterialesSumados unidades',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // SECCIÓN 1: MATERIALES A COMPRAR CONSOLIDADO
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory, color: Color(0xFF1B2A47), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Materiales a Adquirir',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    'Autorizado',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: materialesConsolidados.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final mat = materialesConsolidados[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.check, size: 16, color: Colors.green.shade800),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mat.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (mat.codigo != '-')
                                Text(
                                  'Cód: ${mat.codigo}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${mat.cantidadTotal} unid.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // ============================================================
            // SECCIÓN 2: PROFORMAS AUTORIZADAS POR GERENTE (CON ZOOM)
            // ============================================================
            const Row(
              children: [
                Icon(Icons.photo_library_outlined, color: Color(0xFF1B2A47), size: 20),
                SizedBox(width: 8),
                Text(
                  'Proformas / Cotizaciones Ganadoras',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Toca cualquier imagen para verla en pantalla completa con zoom y verificar precios y datos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),

            if (_cargandoCotizaciones)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1B2A47)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.solicitudes.length,
                itemBuilder: (context, index) {
                  final sol = widget.solicitudes[index];
                  final listaCotiz = _cotizacionesPorSolicitud[sol.idSolicitud] ?? [];

                  // Fotos con estado APROBADA o todas las disponibles si no hay desglose
                  final cotizAprobadas = listaCotiz.where((c) => c.estado == 'APROBADA').toList();
                  final cotizacionesBase = cotizAprobadas.isNotEmpty ? cotizAprobadas : listaCotiz;
                  final cotizacionesAMostrar = cotizacionesBase
                      .where((c) => c.imagenUrl != null && c.imagenUrl!.isNotEmpty)
                      .toList();

                  // También buscar si hay imágenes en detalle_solicitud
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
                              Text(
                                'Solicitud #${sol.idSolicitud}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2A47),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Text(
                                  'AUTORIZADO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (sol.observacion != null && sol.observacion!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              sol.observacion!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Galería de Proformas Autorizadas
                          if (cotizacionesAMostrar.isNotEmpty)
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: cotizacionesAMostrar.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (context, cIdx) {
                                  final cot = cotizacionesAMostrar[cIdx];
                                  final imgUrl = cot.imagenUrl!;
                                  return GestureDetector(
                                    onTap: () => _verImagenCompleta(
                                      imgUrl,
                                      'Proforma Autorizada #${cIdx + 1} - Solicitud #${sol.idSolicitud}',
                                    ),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green.shade400, width: 2),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imgUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                              },
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Proforma #${cIdx + 1}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          else if (fotosDetalles.isNotEmpty)
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotosDetalles.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (context, fIdx) {
                                  final url = fotosDetalles[fIdx];
                                  return GestureDetector(
                                    onTap: () => _verImagenCompleta(
                                      url,
                                      'Proforma Autorizada #${fIdx + 1} - Solicitud #${sol.idSolicitud}',
                                    ),
                                    child: Container(
                                      width: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green.shade400, width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                          },
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sin imagen adjunta.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
