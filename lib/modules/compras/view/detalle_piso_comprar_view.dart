import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
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
  late List<SolicitudModel> _solicitudesLocales;
  bool _cargandoCotizaciones = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _solicitudesLocales = List.from(widget.solicitudes);
    _cargarCotizaciones();
  }

  Future<void> _cargarCotizaciones() async {
    setState(() => _cargandoCotizaciones = true);
    try {
      for (final sol in _solicitudesLocales) {
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
        height: height ?? 140,
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
            height: height ?? 140,
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
        height: height ?? 140,
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
          child: Text('Imagen no disponible', style: TextStyle(color: AppColors.surface)),
        );
      }
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: AppColors.surface));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text('Error al cargar la imagen', style: TextStyle(color: AppColors.surface)),
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
              child: Center(
                child: imageWidget,
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
                  style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.surface, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPRAS: MODAL SEGURO DE CONFIRMACIÓN DE COMPRA Y ALMACÉN
  // ============================================================
  Future<void> _confirmarYMarcarComoComprado(SolicitudModel sol) async {
    final observacionController = TextEditingController();
    bool aceptoVerificacion = false;

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
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified, color: Colors.green.shade800, size: 28),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirmar Compra y Envío a Almacén',
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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ Esta acción registrará la compra física de la Solicitud #${sol.idSolicitud} y transferirá su custodia al Almacén.',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Materiales incluidos en esta compra:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
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
                      final unidad = 'unid.';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $matNombre: $cant $unidad',
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
                    labelText: 'Nº Factura / Proveedor / Notas de Compra',
                    hintText: 'Ej. Factura #F-1024, Proveedor Ferretero',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setModalState(() {
                      aceptoVerificacion = !aceptoVerificacion;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: aceptoVerificacion,
                        onChanged: (val) {
                          setModalState(() {
                            aceptoVerificacion = val ?? false;
                          });
                        },
                        activeColor: Colors.green.shade700,
                      ),
                      const Expanded(
                        child: Text(
                          'Confirmo que he adquirido los materiales físicamente.',
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
              onPressed: aceptoVerificacion ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Confirmar Compra'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) {
      observacionController.dispose();
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final notas = observacionController.text.trim();
      await _comprasController.marcarComoComprado(
        idSolicitud: sol.idSolicitud,
        idUsuarioCompras: widget.idUsuario,
        observacion: notas.isNotEmpty ? notas : 'Materiales adquiridos por Compras y transferidos a Almacén',
      );

      observacionController.dispose();

      if (!mounted) return;

      setState(() {
        _solicitudesLocales.removeWhere((s) => s.idSolicitud == sol.idSolicitud);
        _procesando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Solicitud #${sol.idSolicitud} marcada como COMPRADA. Transferida a Almacén.'),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        ),
      );

      if (_solicitudesLocales.isEmpty) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      observacionController.dispose();
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como comprado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialesConsolidados = ExcelExporter.consolidarMateriales(_solicitudesLocales);
    final totalMaterialesSumados = materialesConsolidados.fold<int>(0, (sum, m) => sum + m.cantidadTotal);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
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
                  colors: [AppColors.primary, Color(0xFF10B981)],
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
                      color: AppColors.surface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_cart_checkout, color: AppColors.surface, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compras Autorizadas por Gerente',
                          style: TextStyle(
                            color: AppColors.surface,
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
                    Icon(Icons.inventory, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Materiales a Adquirir',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                              color: AppColors.surface,
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
                Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Proformas / Cotizaciones Ganadoras',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_solicitudesLocales.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade600),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Todas las compras de este piso fueron completadas!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Los materiales ya fueron transferidos y guardados en Almacén.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _solicitudesLocales.length,
                itemBuilder: (context, index) {
                  final sol = _solicitudesLocales[index];
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
                                  color: AppColors.primary,
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
                                            child: _buildAdaptiveImage(imgUrl, width: 110, height: 140, fit: BoxFit.cover),
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
                                                color: AppColors.surface,
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

                          const SizedBox(height: 16),

                          // BOTÓN DE ACCIÓN SEGURO: MARCAR COMO COMPRADO Y ENVIAR A ALMACÉN
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _procesando ? null : () => _confirmarYMarcarComoComprado(sol),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: AppColors.surface,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.verified_user, size: 20),
                              label: const Text(
                                'Confirmar Compra (Enviar a Almacén)',
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
          ],
        ),
      ),
    );
  }
}
