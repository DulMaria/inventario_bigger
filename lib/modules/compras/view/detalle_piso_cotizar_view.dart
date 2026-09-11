// lib/modules/compras/view/detalle_piso_cotizar_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';

class DetallePisoCotizarView extends StatefulWidget {
  final String nombrePiso;
  final List<SolicitudModel> solicitudes;
  final int idUsuario;
  final String? nombreObra;

  const DetallePisoCotizarView({
    super.key,
    required this.nombrePiso,
    required this.solicitudes,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<DetallePisoCotizarView> createState() => _DetallePisoCotizarViewState();
}

class _ProformaImagenItem {
  File? imagenArchivo;
  String? imagenUrl;
}

class _DetallePisoCotizarViewState extends State<DetallePisoCotizarView> {
  final ComprasController _comprasController = ComprasController();
  final ImagePicker _picker = ImagePicker();

  bool _descargandoExcel = false;
  bool _enviandoProformas = false;

  late List<_ProformaImagenItem> _itemsProformas;

  @override
  void initState() {
    super.initState();
    // Inicializamos con 3 espacios para las 3 fotos mínimas requeridas
    _itemsProformas = List.generate(3, (_) => _ProformaImagenItem());
  }

  int get _fotosCargadasCount =>
      _itemsProformas.where((item) => item.imagenArchivo != null || item.imagenUrl != null).length;

  // ============================================================
  // DESCARGAR EXCEL DEL PISO
  // ============================================================
  Future<void> _descargarExcelPiso() async {
    setState(() => _descargandoExcel = true);
    try {
      final path = await ExcelExporter.exportarPisoIndividualExcel(
        nombrePiso: widget.nombrePiso,
        solicitudes: widget.solicitudes,
        nombreObra: widget.nombreObra,
      );

      if (!mounted) return;
      setState(() => _descargandoExcel = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel del ${widget.nombrePiso} generado: ${path.split(Platform.pathSeparator).last}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _descargandoExcel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SELECCIONAR FOTO
  // ============================================================
  Future<void> _seleccionarFoto(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        setState(() {
          _itemsProformas[index].imagenArchivo = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesFoto(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2FA9E0)),
              title: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _seleccionarFoto(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2FA9E0)),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _seleccionarFoto(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ENVIAR PROFORMAS A GERENCIA
  // ============================================================
  Future<void> _enviarAlGerente() async {
    if (_fotosCargadasCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Debes adjuntar al menos 3 proformas para enviar (Tienes $_fotosCargadasCount/3).'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _enviandoProformas = true);

    try {
      final fotosValidas = _itemsProformas.where((p) => p.imagenArchivo != null).toList();

      for (final sol in widget.solicitudes) {
        final cotizacionesFinales = <CotizacionModel>[];

        for (int i = 0; i < fotosValidas.length; i++) {
          final item = fotosValidas[i];
          final url = await _comprasController.subirImagenProforma(
            archivo: item.imagenArchivo!,
            idSolicitud: sol.idSolicitud,
            indiceCotizacion: i + 1,
          );

          cotizacionesFinales.add(
            CotizacionModel(
              idSolicitud: sol.idSolicitud,
              idUsuario: widget.idUsuario,
              imagenUrl: url,
            ),
          );
        }

        String? primeraImagen = cotizacionesFinales.isNotEmpty ? cotizacionesFinales.first.imagenUrl : null;

        await _comprasController.guardarCotizacionesYEnviarAGerente(
          idSolicitud: sol.idSolicitud,
          idUsuarioCompras: widget.idUsuario,
          cotizaciones: cotizacionesFinales,
          imagenPrincipalProforma: primeraImagen,
        );
      }

      if (!mounted) return;
      setState(() => _enviandoProformas = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${fotosValidas.length} proformas enviadas al Gerente para ${widget.nombrePiso}'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviandoProformas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar proformas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              widget.nombrePiso,
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
        actions: [
          IconButton(
            icon: _descargandoExcel
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Descargar Excel del Piso',
            onPressed: _descargandoExcel ? null : _descargarExcelPiso,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // BANNER INFORMATIVO CON ACCIÓN DE EXCEL
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B2A47), Color(0xFF2FA9E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA9E0).withValues(alpha: 0.25),
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
                    child: const Icon(Icons.layers, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.nombrePiso} - Consolidado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${materialesConsolidados.length} materiales únicos • $totalMaterialesSumados unidades totales',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _descargandoExcel ? null : _descargarExcelPiso,
                    icon: const Icon(Icons.table_chart, size: 16),
                    label: const Text('Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B2A47),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // SECCIÓN 1: MATERIALES A COTIZAR (CONSOLIDACIÓN Y SUMATORIA)
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFF1B2A47), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Materiales Solicitados',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Suma Automática',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
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
                          backgroundColor: const Color(0xFF2FA9E0).withValues(alpha: 0.15),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF1B2A47),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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
                            color: const Color(0xFF1B2A47),
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
            // SECCIÓN 2: SUBIR FOTOS DE PROFORMAS (MÍNIMO 3)
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_camera_outlined, color: Color(0xFF1B2A47), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fotos de Cotizaciones / Proformas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A47)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fotosCargadasCount >= 3 ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _fotosCargadasCount >= 3 ? Colors.green.shade300 : Colors.amber.shade300,
                    ),
                  ),
                  child: Text(
                    '$_fotosCargadasCount / 3 mín.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _fotosCargadasCount >= 3 ? Colors.green.shade800 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Toma o sube directamente las fotos de las proformas recibidas. No necesitas escribir datos ni precios.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),

            // Grid de Fotos
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: _itemsProformas.length + 1,
              itemBuilder: (context, index) {
                // Botón para agregar más de 3 fotos
                if (index == _itemsProformas.length) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _itemsProformas.add(_ProformaImagenItem());
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2FA9E0),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Color(0xFF2FA9E0), size: 30),
                          SizedBox(height: 6),
                          Text(
                            '+ Proforma',
                            style: TextStyle(
                              color: Color(0xFF2FA9E0),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final item = _itemsProformas[index];
                final tieneFoto = item.imagenArchivo != null || item.imagenUrl != null;

                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _mostrarOpcionesFoto(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tieneFoto ? Colors.green.shade400 : Colors.grey.shade300,
                            width: tieneFoto ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: tieneFoto
                              ? (item.imagenArchivo != null
                                  ? Image.file(
                                      item.imagenArchivo!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      item.imagenUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.grey.shade400,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Foto #${index + 1}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (index < 3)
                                      Text(
                                        '(Obligatoria)',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 9,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    if (tieneFoto)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              item.imagenArchivo = null;
                              item.imagenUrl = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // ============================================================
            // BOTÓN ENVIAR A GERENTE
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_enviandoProformas || _fotosCargadasCount < 3) ? null : _enviarAlGerente,
                icon: _enviandoProformas
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _enviandoProformas
                      ? 'Enviando proformas al Gerente...'
                      : 'Enviar Cotizaciones a Gerencia ($_fotosCargadasCount/3)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A47),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
