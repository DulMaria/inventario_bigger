// lib/modules/almacen/view/almacen_home_view.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../../models/solicitud_model.dart';
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

class _AlmacenHomeViewState extends State<AlmacenHomeView> {
  final AlmacenController _almacenController = AlmacenController();

  int _selectedIndex = 0;
  bool _cargando = true;
  bool _procesando = false;
  String _nombreAlmacenero = '';
  String _nombreObra = '';

  List<SolicitudModel> _solicitudesEnAlmacen = [];
  List<SolicitudModel> _solicitudesEntregadas = [];

  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _nombreObra = widget.nombreObra ?? 'Cargando obra...';
    _menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.inventory_2_outlined, 'title': 'Almacén e Inventario'},
      {'icon': Icons.history_outlined, 'title': 'Historial de Entregas'},
      {'icon': Icons.person, 'title': 'Mi Perfil'},
    ];
    _cargarDatosUsuario();
    _cargarDatos();
  }

  void _cambiarVista(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0 || index == 1 || index == 2) {
      _cargarDatos();
    }
  }

  Future<void> _cargarDatosUsuario() async {
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
              _nombreAlmacenero = '$nombre $apellido'.trim();
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
    } catch (e) {
      debugPrint('Error al cargar datos del almacenero: $e');
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final enAlmacen =
          await _almacenController.obtenerMaterialesEnAlmacen(widget.idObra);
      final entregadas =
          await _almacenController.obtenerMaterialesEntregados(widget.idObra);

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
        SnackBar(
          content: Text('Error al cargar datos de Almacén: $e'),
          backgroundColor: Colors.red,
        ),
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

  Widget _buildAdaptiveImage(String? url,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
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
          child: Text('Imagen no disponible',
              style: TextStyle(color: AppColors.surface)),
        );
      }
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
              child: CircularProgressIndicator(color: AppColors.surface));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon:
                    const Icon(Icons.close, color: AppColors.surface, size: 28),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping,
                    color: AppColors.primaryDark, size: 28),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Despachar Material',
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primaryDark, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Confirmarás que la Solicitud #${sol.idSolicitud} fue entregada físicamente al personal en obra.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                              height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Solicitante: ${sol.usuario?.nombreCompleto ?? "Obrero"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryDark),
                ),
                Text(
                  'Piso: ${sol.piso?.nombre ?? "Piso General"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Materiales a Entregar:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryDark),
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
                      final matNombre =
                          d.material?.nombre ?? 'Material #${d.idMaterial}';
                      final cant = d.cantidad;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $matNombre: $cant unid.',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
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
                        activeColor: AppColors.primaryDark,
                      ),
                      const Expanded(
                        child: Text(
                          'Confirmo la entrega física de los materiales en Almacén.',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
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
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Confirmar Despacho',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
        observacion:
            notas.isNotEmpty ? notas : 'Material despachado por Almacén',
      );

      observacionController.dispose();
      await _cargarDatos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ Solicitud #${sol.idSolicitud} marcada como ENTREGADA.'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      observacionController.dispose();
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al despachar material: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _getVista(int index) {
    switch (index) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _buildTabEnAlmacen();
      case 2:
        return _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _buildTabHistorial();
      case 3:
        return const PerfilUsuarioView(isEmbedded: true);
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                        ),
                        if (badge != null && badge > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badge listo(s)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C8A93),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Color(0xFF7C8A93),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _cargarDatosUsuario();
        await _cargarDatos();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de bienvenida Almacén
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
                          Icons.warehouse_outlined,
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
                              _nombreAlmacenero.isNotEmpty
                                  ? '¡Hola, $_nombreAlmacenero!'
                                  : '¡Bienvenido!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Rol: Almacén e Inventario',
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

            // Tarjeta 1: Almacén e Inventario
            _buildMenuCard(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.primaryDark,
              iconBgColor: AppColors.primary.withValues(alpha: 0.12),
              title: 'Almacén e Inventario',
              subtitle:
                  'Gestiona y despacha los materiales comprados listos para entrega.',
              badge: _solicitudesEnAlmacen.length,
              onTap: () => _cambiarVista(1),
            ),

            const SizedBox(height: 12),

            // Tarjeta 2: Historial de Entregas
            _buildMenuCard(
              icon: Icons.history_outlined,
              iconColor: Colors.indigo.shade600,
              iconBgColor: Colors.indigo.shade50,
              title: 'Historial de Entregas',
              subtitle:
                  'Consulta todas las entregas físicas y despachos efectuados en la obra.',
              onTap: () => _cambiarVista(2),
            ),

            const SizedBox(height: 12),

            // Tarjeta 3: Mi Perfil
            _buildMenuCard(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF5A7A8A),
              iconBgColor: Colors.blueGrey.shade50,
              title: 'Mi Perfil',
              subtitle:
                  'Consulta y edita tus datos de usuario y credenciales.',
              onTap: () => _cambiarVista(3),
            ),
          ],
        ),
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
            Icon(Icons.inventory_2_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay materiales pendientes de entrega en Almacén',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark),
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
          final pisoNombre = sol.piso?.nombre ??
              (sol.piso != null
                  ? 'Piso #${sol.piso!.idPiso}'
                  : 'Piso General');
          final fecha =
              '${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}';
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.warehouse_rounded,
                                  color: Colors.green.shade700, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Solicitud #${sol.idSolicitud}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark),
                                  ),
                                  Text(
                                    '$pisoNombre • $fecha',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'EN ALMACÉN',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Solicitado por: $obrero',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (sol.observacion != null &&
                      sol.observacion!.isNotEmpty) ...[
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
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Materiales a Entregar:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: sol.detalles.map((d) {
                        final matNombre =
                            d.material?.nombre ?? 'Material #${d.idMaterial}';
                        final cant = d.cantidad;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(matNombre,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$cant ${d.unidadMedida}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark),
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
                            onTap: () => _verImagenCompleta(url,
                                'Comprobante Solicitud #${sol.idSolicitud}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildAdaptiveImage(url,
                                  width: 90, height: 100),
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
                      onPressed: _procesando
                          ? null
                          : () => _confirmarDespacho(sol),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.local_shipping_outlined,
                          size: 20, color: Colors.white),
                      label: const Text(
                        'Despachar / Entregar a Obrero',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: const [
            SizedBox(height: 40),
            Icon(Icons.history_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aún no hay despachos registrados en el historial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudesEntregadas.length,
        itemBuilder: (context, index) {
          final sol = _solicitudesEntregadas[index];
          final pisoNombre = sol.piso?.nombre ??
              (sol.piso != null
                  ? 'Piso #${sol.piso!.idPiso}'
                  : 'Piso General');
          final fecha =
              '${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year}';
          final obrero = sol.usuario?.nombreCompleto ?? 'Obrero';

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.check_circle,
                    color: AppColors.primaryDark, size: 22),
              ),
              title: Text('Solicitud #${sol.idSolicitud} • $pisoNombre',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                  'Entregado a: $obrero • $fecha\n${sol.observacion ?? ""}'),
              isThreeLine: true,
            ),
          );
        },
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
            tooltip: 'Sincronizar Datos',
            onPressed: () async {
              await _cargarDatosUsuario();
              await _cargarDatos();
            },
          ),
          IconButton(
            icon: const Icon(Icons.domain),
            tooltip: 'Cambiar de Obra',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
              );
            },
          ),
        ],
      ),
      body: _getVista(_selectedIndex),
    );
  }
}
