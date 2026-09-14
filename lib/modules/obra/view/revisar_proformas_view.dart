import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../../compras/controller/compras_controller.dart';

class RevisarProformasView extends StatefulWidget {
  final SolicitudModel solicitud;
  final int idUsuarioGerente;
  final String? nombreObra;
  final bool esAdmin;

  const RevisarProformasView({
    super.key,
    required this.solicitud,
    required this.idUsuarioGerente,
    this.nombreObra,
    this.esAdmin = false,
  });

  @override
  State<RevisarProformasView> createState() => _RevisarProformasViewState();
}

class _RevisarProformasViewState extends State<RevisarProformasView> {
  final ComprasController _comprasController = ComprasController();

  List<CotizacionModel> _cotizaciones = [];
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarCotizaciones();
  }

  Future<void> _cargarCotizaciones() async {
    setState(() {
      _cargando = true;
    });

    try {
      final cotizDb = await _comprasController.obtenerCotizacionesPorSolicitud(
        widget.solicitud.idSolicitud,
      );
      final solFresh = await _comprasController.obtenerSolicitudPorId(
        widget.solicitud.idSolicitud,
      );

      final solUso = solFresh ?? widget.solicitud;
      final listaFinal = <CotizacionModel>[];
      final urlsUsadas = <String>{};

      // 1. Agregar de la tabla cotizaciones DB
      for (final cot in cotizDb) {
        if (cot.imagenUrl != null && cot.imagenUrl!.isNotEmpty) {
          listaFinal.add(cot);
          urlsUsadas.add(cot.imagenUrl!);
        }
      }

      // 2. Extraer de observacion (ej. [PROFORMAS: url1|||url2] o legacy con comas)
      final obsTexto = solUso.observacion ?? widget.solicitud.observacion;
      if (obsTexto != null && obsTexto.contains('[PROFORMAS:')) {
        try {
          final urls = _extraerUrlsProformas(obsTexto);
          for (final url in urls) {
            if (!urlsUsadas.contains(url)) {
              urlsUsadas.add(url);
              listaFinal.add(CotizacionModel(
                idSolicitud: widget.solicitud.idSolicitud,
                idUsuario: 0,
                imagenUrl: url,
                estado: solUso.estado == 'APROBADA' ? 'AUTORIZADA' : 'PENDIENTE',
              ));
            }
          }
        } catch (_) {}
      }

      // 3. Extraer de detalles (rutaImagen)
      final detallesUso = [...solUso.detalles, ...widget.solicitud.detalles];
      for (final d in detallesUso) {
        if (d.rutaImagen != null && d.rutaImagen!.isNotEmpty && !urlsUsadas.contains(d.rutaImagen)) {
          urlsUsadas.add(d.rutaImagen!);
          listaFinal.add(CotizacionModel(
            idSolicitud: widget.solicitud.idSolicitud,
            idUsuario: 0,
            imagenUrl: d.rutaImagen,
            estado: solUso.estado == 'APROBADA' ? 'AUTORIZADA' : 'PENDIENTE',
          ));
        }
      }

      if (!mounted) return;

      setState(() {
        _cotizaciones = listaFinal;
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

  List<String> _extraerUrlsProformas(String obsTexto) {
    if (!obsTexto.contains('[PROFORMAS:')) return [];
    final startIdx = obsTexto.indexOf('[PROFORMAS:') + '[PROFORMAS:'.length;
    final endIdx = obsTexto.indexOf(']', startIdx);
    if (endIdx <= startIdx) return [];

    final contenido = obsTexto.substring(startIdx, endIdx).trim();
    if (contenido.isEmpty) return [];

    // Prioridad 1: Separador nuevo '|||'
    if (contenido.contains('|||')) {
      return contenido
          .split('|||')
          .map((u) => u.trim())
          .where((u) => u.isNotEmpty)
          .toList();
    }

    // Prioridad 2: Expresión regular para Data URIs base64 o URLs HTTP(S) en texto legacy
    final urls = <String>[];
    final regex = RegExp(
      r'(data:image\/[a-zA-Z0-9+\-.]+;base64,[A-Za-z0-9+/=\s]+|https?:\/\/[^\s,\]]+)',
    );
    final matches = regex.allMatches(contenido);
    for (final match in matches) {
      final matchedStr = match.group(0)?.trim();
      if (matchedStr != null && matchedStr.isNotEmpty) {
        urls.add(matchedStr);
      }
    }

    if (urls.isNotEmpty) return urls;

    // Fallback: Separar por comas si no coincide el regex
    return contenido
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
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

  void _verImagenCompleta(String? imagenUrl, String titulo) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta proforma no tiene imagen adjunta.')),
      );
      return;
    }

    Widget imageWidget;
    if (imagenUrl.startsWith('data:image')) {
      final bytes = _tryDecodeBase64(imagenUrl);
      if (bytes != null && bytes.isNotEmpty) {
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white70, size: 64),
                SizedBox(height: 12),
                Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      } else {
        imageWidget = const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white70, size: 64),
              SizedBox(height: 12),
              Text('Formato de imagen no válido', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }
    } else {
      imageWidget = Image.network(
        imagenUrl,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white70, size: 64),
              SizedBox(height: 12),
              Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: imageWidget,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autorizarCotizacion(CotizacionModel cot, int index) async {
    final observacionController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Autorizar Proforma')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas autorizar la Proforma #${index + 1} para la compra de estos materiales?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observacionController,
              decoration: const InputDecoration(
                labelText: 'Comentario de Aprobación (Opcional)',
                hintText: 'Ej. Precios revisados y aprobados.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar y Autorizar'),
          ),
        ],
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
      await _comprasController.autorizarCotizacion(
        idSolicitud: widget.solicitud.idSolicitud,
        idCotizacion: cot.idCotizacion ?? 0,
        idUsuarioGerente: widget.idUsuarioGerente,
        observacionGerente: observacionController.text.trim().isNotEmpty
            ? observacionController.text.trim()
            : 'Proforma #${index + 1} autorizada por ${widget.esAdmin ? "Administrador" : "Gerente"}',
        rutaImagenGanadora: cot.imagenUrl,
      );

      observacionController.dispose();

      if (!mounted) return;

      setState(() {
        _procesando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Proforma #${index + 1} autorizada exitosamente para compra.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      observacionController.dispose();
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al autorizar proforma: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildImageThumbnail(String? imagenUrl, String titulo) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return Container(
        height: 180,
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              SizedBox(height: 6),
              Text('Sin imagen adjunta', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (imagenUrl.startsWith('data:image')) {
      final bytes = _tryDecodeBase64(imagenUrl);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 180,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          ),
        );
      } else {
        return Container(
          height: 180,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
        );
      }
    }

    return Image.network(
      imagenUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detalles = widget.solicitud.detalles;
    final pisoNombre = widget.solicitud.piso?.nombre ?? (widget.solicitud.piso != null ? "Piso #${widget.solicitud.piso!.idPiso}" : "Piso");
    final fecha = '${widget.solicitud.fecha.day}/${widget.solicitud.fecha.month}/${widget.solicitud.fecha.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: Text('Revisar Proformas #${widget.solicitud.idSolicitud}'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _procesando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Autorizando proforma seleccionada...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TARJETA RESUMEN DE LA ORDEN DE MATERIALES
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F3FC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long, color: Color(0xFF2FA9E0)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Obra: ${widget.nombreObra ?? "Obra"} - $pisoNombre',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Fecha: $fecha', style: const TextStyle(fontSize: 12, color: Color(0xFF7C8A93))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          const Text(
                            'Materiales solicitados:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          ...detalles.map((d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, size: 14, color: Color(0xFF2FA9E0)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        d.material?.nombre ?? (d.material != null ? 'Material #${d.material!.idMaterial}' : 'Material'),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '${d.cantidad} unid.',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. FOTOS DE PROFORMAS RECIBIDAS
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, color: Color(0xFF2FA9E0)),
                      const SizedBox(width: 8),
                      Text(
                        'Fotos de Proformas Recibidas (${_cotizaciones.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2A32)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca cualquier imagen para verla en pantalla completa con zoom y autoriza la mejor opción:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                  ),
                  const SizedBox(height: 14),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_cotizaciones.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No se encontraron imágenes de proformas para esta solicitud.',
                            style: TextStyle(color: Color(0xFF7C8A93)),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_cotizaciones.length, (index) {
                      final cot = _cotizaciones[index];
                      final titulo = 'Proforma #${index + 1}';
                      final tieneFoto = cot.imagenUrl != null && cot.imagenUrl!.isNotEmpty;
                      final esGanadora = cot.estado == 'SELECCIONADA';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 18),
                        elevation: esGanadora ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: esGanadora ? Colors.green : Colors.grey.shade300,
                            width: esGanadora ? 2.5 : 1,
                          ),
                        ),
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
                                        backgroundColor: esGanadora ? Colors.green.shade100 : const Color(0xFFE1F3FC),
                                        child: Icon(
                                          esGanadora ? Icons.stars : Icons.image,
                                          color: esGanadora ? Colors.green.shade700 : const Color(0xFF2FA9E0),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        titulo,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (esGanadora)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'AUTORIZADA',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // IMAGEN DE LA PROFORMA CON TAP PARA PANTALLA COMPLETA
                              InkWell(
                                onTap: tieneFoto ? () => _verImagenCompleta(cot.imagenUrl, titulo) : null,
                                borderRadius: BorderRadius.circular(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      _buildImageThumbnail(cot.imagenUrl, titulo),
                                      if (tieneFoto)
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                SizedBox(width: 4),
                                                Text('Ver completa', style: TextStyle(color: Colors.white, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // BOTÓN DE AUTORIZACIÓN
                              if (!esGanadora && widget.solicitud.estado != 'APROBADA')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _autorizarCotizacion(cot, index),
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                    label: Text(
                                      'Autorizar $titulo para Compra',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
