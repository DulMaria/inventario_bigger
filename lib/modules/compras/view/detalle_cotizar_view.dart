// lib/modules/compras/view/detalle_cotizar_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';

class DetalleCotizarView extends StatefulWidget {
  final SolicitudModel solicitud;
  final int idUsuarioCompras;
  final String? nombreObra;

  const DetalleCotizarView({
    super.key,
    required this.solicitud,
    required this.idUsuarioCompras,
    this.nombreObra,
  });

  @override
  State<DetalleCotizarView> createState() => _DetalleCotizarViewState();
}

class _ProformaImagenItem {
  File? imagenArchivo;
  String? imagenUrl;
}

class _DetalleCotizarViewState extends State<DetalleCotizarView> {
  final ComprasController _comprasController = ComprasController();
  final ImagePicker _picker = ImagePicker();

  final List<_ProformaImagenItem> _proformas = [];
  bool _enviando = false;
  bool _descargandoExcel = false;

  @override
  void initState() {
    super.initState();
    // Iniciar con 3 espacios de proforma listos para subir fotos
    _proformas.add(_ProformaImagenItem());
    _proformas.add(_ProformaImagenItem());
    _proformas.add(_ProformaImagenItem());
  }

  void _agregarProforma() {
    setState(() {
      _proformas.add(_ProformaImagenItem());
    });
  }

  void _eliminarProforma(int index) {
    if (_proformas.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe existir al menos un espacio de proforma.')),
      );
      return;
    }
    setState(() {
      _proformas.removeAt(index);
    });
  }

  Future<void> _seleccionarImagen(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked != null) {
        setState(() {
          _proformas[index].imagenArchivo = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _mostrarOpcionesImagen(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subir Proforma #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESCARGAR EXCEL DIRECTAMENTE
  // ============================================================
  Future<void> _descargarExcelDirecto() async {
    setState(() {
      _descargandoExcel = true;
    });

    try {
      final filePath = await ExcelExporter.exportarSolicitudACotizarExcel(
        solicitud: widget.solicitud,
        nombreObra: widget.nombreObra,
      );

      if (!mounted) return;

      setState(() {
        _descargandoExcel = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel generado y abierto correctamente: ${filePath.split(Platform.pathSeparator).last}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargandoExcel = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ENVIAR PROFORMAS A REVISIÓN DEL GERENTE
  // ============================================================
  Future<void> _enviarProformasAGerente() async {
    final imagenesCargadas = _proformas.where((p) => p.imagenArchivo != null || p.imagenUrl != null).toList();

    if (imagenesCargadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes adjuntar al menos una imagen de proforma para enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (imagenesCargadas.length < 3) {
      final proceder = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recomendación de Proformas'),
          content: Text(
            'Has adjuntado ${imagenesCargadas.length} proforma(s). Se recomienda subir 3 o más para que el Gerente pueda comparar. ¿Deseas enviar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Adjuntar más'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar así'),
            ),
          ],
        ),
      );

      if (proceder != true) return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final cotizacionesFinales = <CotizacionModel>[];

      for (int i = 0; i < imagenesCargadas.length; i++) {
        final item = imagenesCargadas[i];
        String? url = item.imagenUrl;

        if (item.imagenArchivo != null) {
          url = await _comprasController.subirImagenProforma(
            archivo: item.imagenArchivo!,
            idSolicitud: widget.solicitud.idSolicitud,
            indiceCotizacion: i + 1,
          );
        }

        cotizacionesFinales.add(
          CotizacionModel(
            idSolicitud: widget.solicitud.idSolicitud,
            idUsuario: widget.idUsuarioCompras,
            imagenUrl: url,
          ),
        );
      }

      String? primeraImagen = cotizacionesFinales.isNotEmpty ? cotizacionesFinales.first.imagenUrl : null;

      await _comprasController.guardarCotizacionesYEnviarAGerente(
        idSolicitud: widget.solicitud.idSolicitud,
        idUsuarioCompras: widget.idUsuarioCompras,
        cotizaciones: cotizacionesFinales,
        imagenPrincipalProforma: primeraImagen,
      );

      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proformas enviadas al Gerente exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar proformas: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalles = widget.solicitud.detalles;
    final pisoNombre = widget.solicitud.piso?.nombre ?? (widget.solicitud.piso != null ? 'Piso #${widget.solicitud.piso!.idPiso}' : 'Piso');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Cotizar Solicitud #${widget.solicitud.idSolicitud}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: _enviando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo proformas y enviando a Gerente...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TARJETA RESUMEN DE MATERIALES A COTIZAR
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
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Piso: $pisoNombre',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E2A32),
                                      ),
                                    ),
                                    Text(
                                      'Técnico: ${widget.solicitud.usuario?.nombre ?? "Técnico"} ${widget.solicitud.usuario?.apellido ?? ""}',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Text(
                                  'A Cotizar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Materiales solicitados:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ...detalles.map((d) {
                            final mat = d.material;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mat?.nombre ?? (mat != null ? 'Material #${mat.idMaterial}' : 'Material'),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${d.cantidad} unid.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1D7FAE),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // BOTÓN DE DESCARGA DIRECTA EN EXCEL (.xlsx)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _descargandoExcel ? null : _descargarExcelDirecto,
                              icon: _descargandoExcel
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                                    )
                                  : const Icon(Icons.file_download, color: AppColors.surface),
                              label: Text(
                                _descargandoExcel
                                    ? 'Generando archivo Excel...'
                                    : 'Descargar Lista en Excel (.xlsx)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF107C41), // Color Verde Excel oficial
                                foregroundColor: AppColors.surface,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. SECCIÓN DE FOTOS DE PROFORMAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fotos de Proformas (3 o más)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A32),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _agregarProforma,
                        icon: const Icon(Icons.add_photo_alternate, size: 18, color: AppColors.primary),
                        label: const Text('+ Proforma', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const Text(
                    'Sube las fotos de las proformas adquiridas para que el Gerente las revise y seleccione.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7C8A93)),
                  ),
                  const SizedBox(height: 14),

                  // GRILLA / LISTA DE PROFORMAS
                  ...List.generate(_proformas.length, (index) {
                    final item = _proformas[index];
                    final tieneFoto = item.imagenArchivo != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Proforma #${index + 1}',
                                        style: const TextStyle(
                                          color: AppColors.surface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (tieneFoto)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check, size: 12, color: Colors.green.shade800),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Foto cargada',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (_proformas.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminarProforma(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (tieneFoto) ...[
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      item.imagenArchivo!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 16,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, color: AppColors.surface, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            item.imagenArchivo = null;
                                            item.imagenUrl = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            InkWell(
                              onTap: () => _mostrarOpcionesImagen(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      tieneFoto ? Icons.replay : Icons.add_a_photo,
                                      color: const Color(0xFF1D7FAE),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tieneFoto ? 'Cambiar Foto de Proforma' : 'Tomar / Subir Foto de Proforma',
                                      style: const TextStyle(
                                        color: Color(0xFF1D7FAE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // BOTÓN PARA ENVIAR PROFORMAS AL GERENTE
                  ElevatedButton.icon(
                    onPressed: _enviarProformasAGerente,
                    icon: const Icon(Icons.send_rounded, color: AppColors.surface),
                    label: const Text(
                      'Enviar Proformas al Gerente',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
