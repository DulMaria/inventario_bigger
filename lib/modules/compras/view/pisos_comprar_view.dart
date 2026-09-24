// lib/modules/compras/view/pisos_comprar_view.dart
import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../models/solicitud_model.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';
import 'detalle_piso_comprar_view.dart';

class PisosComprarView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;
  final bool esHistorial;
  final bool isEmbedded;

  const PisosComprarView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
    this.esHistorial = false,
    this.isEmbedded = false,
  });

  @override
  State<PisosComprarView> createState() => _PisosComprarViewState();
}

class _PisosComprarViewState extends State<PisosComprarView> {
  final ComprasController _comprasController = ComprasController();

  bool _cargando = true;
  List<SolicitudModel> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final lista = widget.esHistorial
          ? await _comprasController.obtenerSolicitudesCompradas(widget.idObra)
          : await _comprasController.obtenerSolicitudesAprobadas(widget.idObra);

      if (!mounted) return;
      setState(() {
        _solicitudes = lista;
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

  @override
  Widget build(BuildContext context) {
    final mapaPisos = _agruparPorPiso(_solicitudes);

    final Widget bodyContent = _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _cargarDatos,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ============================================================
                // BANNER SUPERIOR INFORMATIVO
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.esHistorial
                          ? const [Color(0xFF4B5563), Color(0xFF6B7280)]
                          : const [AppColors.primary, Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.esHistorial
                                ? const Color(0xFF4B5563)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.25),
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
                        child: Icon(
                          widget.esHistorial ? Icons.history_edu : Icons.verified,
                          color: AppColors.surface,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.esHistorial
                                  ? 'Historial de Compras'
                                  : 'Cotizaciones Autorizadas',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.esHistorial
                                  ? 'Consulta los pedidos comprados y finalizados por piso'
                                  : 'Selecciona un piso para ver las proformas ganadoras y comprar',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.esHistorial
                            ? 'Pisos con Compras (${mapaPisos.length})'
                            : 'Pisos Listos para Compra (${mapaPisos.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      widget.esHistorial ? 'Histórico' : 'Pisos autorizados',
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
                        Icon(
                          widget.esHistorial
                              ? Icons.history_toggle_off
                              : Icons.hourglass_empty_rounded,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.esHistorial
                              ? 'No hay compras registradas en el historial'
                              : 'No hay compras autorizadas pendientes',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.esHistorial
                              ? 'Las órdenes compradas aparecerán aquí organizadas por piso.'
                              : 'Cuando el Gerente autorice una cotización, aparecerá aquí organizada por piso.',
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetallePisoComprarView(
                                  nombrePiso: nombrePiso,
                                  solicitudes: solicitudesDelPiso,
                                  idUsuario: widget.idUsuario,
                                  nombreObra: widget.nombreObra,
                                ),
                              ),
                            );
                            _cargarDatos();
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
                                        color: widget.esHistorial
                                            ? Colors.grey.shade100
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        widget.esHistorial
                                            ? Icons.inventory
                                            : Icons.shopping_bag,
                                        color: widget.esHistorial
                                            ? const Color(0xFF4B5563)
                                            : Colors.green.shade700,
                                        size: 24,
                                      ),
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
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            '${solicitudesDelPiso.length} orden(es) • ${materialesConsolidados.length} materiales',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: widget.esHistorial
                                          ? const Color(0xFF4B5563)
                                          : const Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            widget.esHistorial
                                                ? Icons.check_circle_outline
                                                : Icons.check_circle,
                                            size: 16,
                                            color: widget.esHistorial
                                                ? Colors.grey.shade600
                                                : Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Total: $totalUnidades unid.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.esHistorial
                                            ? Colors.grey.shade100
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: widget.esHistorial
                                              ? Colors.grey.shade300
                                              : Colors.green.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        widget.esHistorial ? 'COMPRADO' : 'AUTORIZADO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: widget.esHistorial
                                              ? const Color(0xFF374151)
                                              : Colors.green.shade800,
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
          );

    if (widget.isEmbedded) {
      return Container(
        color: AppColors.backgroundLight,
        child: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.esHistorial ? 'Historial de Compras' : 'Materiales a Comprar',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
