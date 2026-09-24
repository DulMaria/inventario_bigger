// lib/modules/compras/view/compras_home_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../../models/solicitud_model.dart';
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

  int _selectedIndex = 0;
  String _nombreUsuario = '';
  String _nombreObra = '';

  bool _cargando = true;
  bool _descargandoExcel = false;
  List<SolicitudModel> _solicitudesACotizar = [];
  List<SolicitudModel> _solicitudesAprobadas = [];
  List<SolicitudModel> _solicitudesCompradas = [];

  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _nombreObra = widget.nombreObra ?? 'Cargando obra...';
    _menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.request_quote_outlined, 'title': 'Materiales a Cotizar'},
      {'icon': Icons.shopping_cart_checkout, 'title': 'Materiales a Comprar'},
      {'icon': Icons.history_edu_outlined, 'title': 'Historial de Compras'},
      {'icon': Icons.table_chart_outlined, 'title': 'Plantilla de Excel'},
      {'icon': Icons.person, 'title': 'Mi Perfil'},
    ];
    _cargarDatos();
  }

  void _cambiarVista(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final usuarioData = await Supabase.instance.client
            .from('usuarios')
            .select('nombre, apellido')
            .eq('id_auth', user.id)
            .maybeSingle();

        if (usuarioData != null) {
          final nombre = usuarioData['nombre'] ?? '';
          final apellido = usuarioData['apellido'] ?? '';
          if (mounted) {
            setState(() {
              _nombreUsuario = '$nombre $apellido'.trim();
            });
          }
        }
      }

      if (widget.idObra > 0) {
        final obraData = await Supabase.instance.client
            .from('obras')
            .select('nombre')
            .eq('id_obra', widget.idObra)
            .maybeSingle();

        if (obraData != null && obraData['nombre'] != null) {
          if (mounted) {
            setState(() {
              _nombreObra = obraData['nombre'];
            });
          }
        }
      }

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
        nombreObra: _nombreObra,
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

  Widget _getVista(int index) {
    switch (index) {
      case 0:
        return _buildDashboardView();
      case 1:
        return PisosCotizarView(
          idObra: widget.idObra,
          idUsuario: widget.idUsuario,
          nombreObra: _nombreObra,
          isEmbedded: true,
        );
      case 2:
        return PisosComprarView(
          idObra: widget.idObra,
          idUsuario: widget.idUsuario,
          nombreObra: _nombreObra,
          esHistorial: false,
          isEmbedded: true,
        );
      case 3:
        return PisosComprarView(
          idObra: widget.idObra,
          idUsuario: widget.idUsuario,
          nombreObra: _nombreObra,
          esHistorial: true,
          isEmbedded: true,
        );
      case 4:
        return _buildPlantillaExcelView();
      case 5:
        return const PerfilUsuarioView(isEmbedded: true);
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final mapaPisosACotizar = _agruparPorPiso(_solicitudesACotizar);
    final mapaPisosAComprar = _agruparPorPiso(_solicitudesAprobadas);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // BANNER DE BIENVENIDA COMPRAS
            // ============================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nombreUsuario.isNotEmpty
                                  ? '¡Hola, $_nombreUsuario!'
                                  : '¡Bienvenido a Compras!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Encargado de Adquisiciones',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Obra: $_nombreObra',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Módulos de Gestión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),

            const SizedBox(height: 14),

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
              colorPrimario: AppColors.primary,
              colorGradiente: AppColors.primaryDark,
              badgeColor: Colors.blue.shade50,
              badgeTextColor: AppColors.primaryDark,
              onTap: () => _cambiarVista(1),
            ),

            const SizedBox(height: 14),

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
              onTap: () => _cambiarVista(2),
            ),

            const SizedBox(height: 14),

            // ========================================================
            // BOTÓN 3: HISTORIAL DE COMPRAS
            // ========================================================
            _buildMenuCard(
              titulo: 'Historial de Compras',
              subtitulo:
                  'Consulta el historial de todas las órdenes de compras efectuadas y finalizadas por piso.',
              badgeTexto: '${_solicitudesCompradas.length} Compradas',
              badgeDetalle: 'Finalizadas',
              icono: Icons.history_edu_rounded,
              colorPrimario: const Color(0xFF4B5563),
              colorGradiente: const Color(0xFF6B7280),
              badgeColor: Colors.grey.shade100,
              badgeTextColor: const Color(0xFF374151),
              onTap: () => _cambiarVista(3),
            ),

            const SizedBox(height: 14),

            // ========================================================
            // ACCIÓN RÁPIDA: EXPORTAR EXCEL GLOBAL
            // ========================================================
            Card(
              elevation: 2,
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
                            '${mapaPisosACotizar.length} pisos listos para cotizar.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _descargandoExcel ? null : _descargarExcelGlobal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: _descargandoExcel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                            )
                          : const Text(
                              'Exportar',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
  }

  Widget _buildPlantillaExcelView() {
    final mapaPisos = _agruparPorPiso(_solicitudesACotizar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F766E),
                  Color(0xFF0D9488),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.file_download_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exportación de Planilla Excel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Genera el archivo con pestañas por cada piso',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Este formato consolida automáticamente todas las solicitudes de materiales agrupadas por cada piso para enviar a proveedores y cotizar.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Estado de Cotizaciones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A32)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pisos con solicitudes activas:', style: TextStyle(color: Color(0xFF7C8A93))),
                      Text('${mapaPisos.length} pisos', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total de órdenes a cotizar:', style: TextStyle(color: Color(0xFF7C8A93))),
                      Text('${_solicitudesACotizar.length} órdenes', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (_descargandoExcel || mapaPisos.isEmpty)
                          ? null
                          : _descargarExcelGlobal,
                      icon: _descargandoExcel
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.file_download, color: Colors.white),
                      label: Text(
                        _descargandoExcel ? 'Generando Excel...' : 'Descargar Planilla Excel Completa',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorPrimario, colorGradiente],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2A32),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C8A93),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeTextColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  badgeTexto,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF7C8A93),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: CustomDrawer(
        selectedIndex: _selectedIndex,
        menuItems: _menuItems,
        onItemSelected: _cambiarVista,
      ),
      appBar: AppBar(
        leading: _selectedIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Volver al Dashboard',
                onPressed: () => _cambiarVista(0),
              )
            : null,
        title: Text(_menuItems[_selectedIndex]['title']),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.domain),
            tooltip: 'Cambiar Obra',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
              );
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _getVista(_selectedIndex),
    );
  }
}
