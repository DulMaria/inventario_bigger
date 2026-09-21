// lib/modules/compras/view/compras_home_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../../models/solicitud_model.dart';
import '../../auth/view/login_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import '../controller/compras_controller.dart';
import '../utils/excel_exporter.dart';
import 'pisos_cotizar_view.dart';
import 'pisos_comprar_view.dart';

class ComprasHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;

  const ComprasHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<ComprasHomeView> createState() => _ComprasHomeViewState();
}

class _ComprasHomeViewState extends State<ComprasHomeView> {
  final ComprasController _comprasController = ComprasController();

  bool _cargando = true;
  bool _descargandoExcel = false;
  List<SolicitudModel> _solicitudesACotizar = [];
  List<SolicitudModel> _solicitudesAprobadas = [];
  List<SolicitudModel> _solicitudesCompradas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final aCotizar = await _comprasController.obtenerSolicitudesACotizar(widget.idObra);
      final aprobadas = await _comprasController.obtenerSolicitudesAprobadas(widget.idObra);
      final compradas = await _comprasController.obtenerSolicitudesCompradas(widget.idObra);

      if (!mounted) return;
      setState(() {
        _solicitudesACotizar = aCotizar;
        _solicitudesAprobadas = aprobadas;
        _solicitudesCompradas = compradas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar datos: $e'), backgroundColor: Colors.red),
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

  // Descargar Excel Global Multi-Pestaña
  Future<void> _descargarExcelGlobal() async {
    final mapaPisos = _agruparPorPiso(_solicitudesACotizar);
    if (mapaPisos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay solicitudes pendientes de cotización para exportar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _descargandoExcel = true);
    try {
      final path = await ExcelExporter.exportarMultiplesPisosExcel(
        solicitudesPorPiso: mapaPisos,
        nombreObra: widget.nombreObra,
      );

      if (!mounted) return;
      setState(() => _descargandoExcel = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel descargado (${mapaPisos.length} pisos): ${path.split(Platform.pathSeparator).last}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _descargandoExcel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Cerrar Sesión
  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // Cambiar Obra
  void _cambiarObra() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapaPisosACotizar = _agruparPorPiso(_solicitudesACotizar);
    final mapaPisosAComprar = _agruparPorPiso(_solicitudesAprobadas);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      drawer: const CustomDrawer(),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        title: Text(widget.nombreObra ?? 'Panel'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
                (route) => false,
              );
            },
            tooltip: 'Cambiar Obra',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2A47)))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: const Color(0xFF1B2A47),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // HEADER PRINCIPAL CON INFORMACIÓN DE OBRA Y ACCIONES
                    // ============================================================
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B2A47), Color(0xFF2FA9E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                                          color: Colors.white.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 10),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BYGGER COMPRAS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          Text(
                                            'Encargado de Compras',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz, color: Colors.white),
                                        tooltip: 'Cambiar de Obra',
                                        onPressed: _cambiarObra,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.logout, color: Colors.white),
                                        tooltip: 'Cerrar Sesión',
                                        onPressed: _cerrarSesion,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.nombreObra ?? 'Obra Seleccionada',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Panel de Gestión y Adquisiciones',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ============================================================
                    // MENÚ PRINCIPAL: 2 BOTONES DESTACADOS
                    // ============================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Módulos de Gestión',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2A47),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecciona el flujo para ver los pisos y requerimientos.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 18),

                          // ========================================================
                          // BOTÓN 1: MATERIALES A COTIZAR
                          // ========================================================
                          _buildMenuCard(
                            titulo: 'Materiales a Cotizar',
                            subtitulo:
                                'Visualiza los pisos solicitados, genera el Excel de cotización y sube las fotos de las proformas.',
                            badgeTexto: '${mapaPisosACotizar.length} Pisos',
                            badgeDetalle: '${_solicitudesACotizar.length} órdenes',
                            icono: Icons.request_quote_rounded,
                            colorPrimario: const Color(0xFF1B2A47),
                            colorGradiente: const Color(0xFF2FA9E0),
                            badgeColor: Colors.blue.shade50,
                            badgeTextColor: const Color(0xFF1B2A47),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PisosCotizarView(
                                    idObra: widget.idObra,
                                    idUsuario: widget.idUsuario,
                                    nombreObra: widget.nombreObra,
                                  ),
                                ),
                              );
                              _cargarDatos();
                            },
                          ),

                          const SizedBox(height: 18),

                          // ========================================================
                          // BOTÓN 2: MATERIALES A COMPRAR
                          // ========================================================
                          _buildMenuCard(
                            titulo: 'Materiales a Comprar',
                            subtitulo:
                                'Accede a los pisos con cotizaciones autorizadas por Gerencia para ver la proforma ganadora y comprar.',
                            badgeTexto: '${mapaPisosAComprar.length} Pisos',
                            badgeDetalle: '${_solicitudesAprobadas.length} autorizadas',
                            icono: Icons.shopping_cart_checkout_rounded,
                            colorPrimario: const Color(0xFF065F46),
                            colorGradiente: const Color(0xFF10B981),
                            badgeColor: Colors.green.shade50,
                            badgeTextColor: const Color(0xFF065F46),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PisosComprarView(
                                    idObra: widget.idObra,
                                    idUsuario: widget.idUsuario,
                                    nombreObra: widget.nombreObra,
                                  ),
                                ),
                              );
                              _cargarDatos();
                            },
                          ),

                          const SizedBox(height: 18),

                          // ========================================================
                          // BOTÓN 3: HISTORIAL DE COMPRAS
                          // ========================================================
                          _buildMenuCard(
                            titulo: 'Historial de Compras',
                            subtitulo:
                                'Consulta el historial de todas las órdenes de compras efectuadas y finalizadas.',
                            badgeTexto: '${_solicitudesCompradas.length} Compradas',
                            badgeDetalle: 'Finalizadas',
                            icono: Icons.history_edu_rounded,
                            colorPrimario: const Color(0xFF4B5563),
                            colorGradiente: const Color(0xFF6B7280),
                            badgeColor: Colors.grey.shade100,
                            badgeTextColor: const Color(0xFF374151),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PisosComprarView(
                                    idObra: widget.idObra,
                                    idUsuario: widget.idUsuario,
                                    nombreObra: widget.nombreObra,
                                  ),
                                ),
                              );
                              _cargarDatos();
                            },
                          ),

                          const SizedBox(height: 24),

                          // ========================================================
                          // ACCIÓN RÁPIDA: EXPORTAR EXCEL GLOBAL
                          // ========================================================
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.table_chart, color: Colors.green.shade700, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Planilla Excel Completa',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          'Exporta todas las cotizaciones de la obra divididas en pestañas por piso.',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _descargandoExcel ? null : _descargarExcelGlobal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B2A47),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    child: _descargandoExcel
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Exportar', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required String titulo,
    required String subtitulo,
    required String badgeTexto,
    required String badgeDetalle,
    required IconData icono,
    required Color colorPrimario,
    required Color colorGradiente,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorPrimario, colorGradiente],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icono, color: Colors.white, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            badgeTexto,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($badgeDetalle)',
                            style: TextStyle(
                              color: badgeTextColor.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Ingresar al módulo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorGradiente,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: colorGradiente),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
