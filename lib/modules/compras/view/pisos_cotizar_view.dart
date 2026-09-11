// lib/modules/compras/view/pisos_cotizar_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/solicitud_model.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';
import 'detalle_piso_cotizar_view.dart';

class PisosCotizarView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;

  const PisosCotizarView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<PisosCotizarView> createState() => _PisosCotizarViewState();
}

class _PisosCotizarViewState extends State<PisosCotizarView> {
  final ComprasController _comprasController = ComprasController();

  bool _cargando = true;
  bool _descargandoExcelGlobal = false;
  List<SolicitudModel> _solicitudesACotizar = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final aCotizar = await _comprasController.obtenerSolicitudesACotizar(widget.idObra);
      if (!mounted) return;
      setState(() {
        _solicitudesACotizar = aCotizar;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Agrupar por Piso
  Map<String, List<SolicitudModel>> _agruparPorPiso(List<SolicitudModel> lista) {
    final Map<String, List<SolicitudModel>> mapa = {};
    for (final sol in lista) {
      final nombrePiso = sol.piso?.nombre ?? 'Piso General';
      if (!mapa.containsKey(nombrePiso)) {
        mapa[nombrePiso] = [];
      }
      mapa[nombrePiso]!.add(sol);
    }
    return mapa;
  }

  // Descargar Excel Global Multi-Piso
  Future<void> _descargarExcelGlobal(Map<String, List<SolicitudModel>> mapaPisos) async {
    if (mapaPisos.isEmpty) return;

    setState(() => _descargandoExcelGlobal = true);
    try {
      final path = await ExcelExporter.exportarMultiplesPisosExcel(
        solicitudesPorPiso: mapaPisos,
        nombreObra: widget.nombreObra,
      );

      if (!mounted) return;
      setState(() => _descargandoExcelGlobal = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel descargado con ${mapaPisos.length} pestañas por piso: ${path.split(Platform.pathSeparator).last}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _descargandoExcelGlobal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapaPisos = _agruparPorPiso(_solicitudesACotizar);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Materiales a Cotizar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2A47)))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: const Color(0xFF1B2A47),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ============================================================
                  // BANNER MULTI-HOJA EXCEL
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.description, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Planilla de Cotización Excel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Multi-pestaña separada por pisos con suma de cantidades',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_descargandoExcelGlobal || mapaPisos.isEmpty)
                                ? null
                                : () => _descargarExcelGlobal(mapaPisos),
                            icon: _descargandoExcelGlobal
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B2A47)),
                                  )
                                : const Icon(Icons.file_download, size: 18),
                            label: Text(
                              _descargandoExcelGlobal
                                  ? 'Generando Excel...'
                                  : 'Descargar Excel General (${mapaPisos.length} Pisos)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B2A47),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pisos con Solicitudes (${mapaPisos.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2A47),
                        ),
                      ),
                      Text(
                        'Selecciona un piso para ver detalle',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (mapaPisos.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay solicitudes pendientes por cotizar',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Todas las solicitudes han sido cotizadas o están en revisión por Gerencia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mapaPisos.keys.length,
                      itemBuilder: (context, index) {
                        final nombrePiso = mapaPisos.keys.elementAt(index);
                        final solicitudesDelPiso = mapaPisos[nombrePiso]!;
                        final materialesConsolidados = ExcelExporter.consolidarMateriales(solicitudesDelPiso);
                        final totalUnidades = materialesConsolidados.fold<int>(0, (sum, m) => sum + m.cantidadTotal);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetallePisoCotizarView(
                                    nombrePiso: nombrePiso,
                                    solicitudes: solicitudesDelPiso,
                                    idUsuario: widget.idUsuario,
                                    nombreObra: widget.nombreObra,
                                  ),
                                ),
                              );
                              if (res == true) {
                                _cargarDatos();
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2FA9E0).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.layers, color: Color(0xFF2FA9E0), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombrePiso,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B2A47),
                                              ),
                                            ),
                                            Text(
                                              '${solicitudesDelPiso.length} orden(es) • ${materialesConsolidados.length} materiales únicos',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFF2FA9E0)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade700),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Total consolidado: ',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                          Text(
                                            '$totalUnidades unid.',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B2A47),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          'Pendiente Cotizar',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
