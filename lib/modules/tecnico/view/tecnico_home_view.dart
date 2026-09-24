import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';
import '../../piso/view/piso_obrero_view.dart' show PisosObraView;
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import 'solicitudes_obreros_view.dart';
import 'historial_tecnico_view.dart';

class TecnicoHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;

  const TecnicoHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<TecnicoHomeView> createState() => _TecnicoHomeViewState();
}

class _TecnicoHomeViewState extends State<TecnicoHomeView> {
  final SolicitudObreroController _solicitudController =
      SolicitudObreroController();
  int _selectedIndex = 0;
  int _conteoPendientes = 0;
  String _nombreTecnico = '';
  String _nombreObra = '';

  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _nombreObra = widget.nombreObra ?? 'Cargando obra...';
    _menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.layers_outlined, 'title': 'Pisos de la Obra'},
      {'icon': Icons.pending_actions, 'title': 'Solicitud de Materiales'},
      {'icon': Icons.history, 'title': 'Historial de la Obra'},
      {'icon': Icons.person, 'title': 'Mi Perfil'},
    ];
    _cargarDatos();
    _cargarConteo();
  }

  void _cambiarVista(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0 || index == 2) {
      _cargarConteo();
    }
  }

  Future<void> _cargarConteo() async {
    try {
      final pendientes =
          await _solicitudController.obtenerSolicitudesPendientes(widget.idObra);
      if (!mounted) return;
      setState(() {
        _conteoPendientes = pendientes.length;
      });
    } catch (_) {
      // Manejar silenciosamente en segundo plano
    }
  }

  Future<void> _cargarDatos() async {
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
              _nombreTecnico = '$nombre $apellido'.trim();
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
      debugPrint('Error al cargar datos del técnico: $e');
    }
  }

  Widget _getVista(int index) {
    switch (index) {
      case 0:
        return _buildDashboardView();
      case 1:
        return PisosObraView(
          idObra: widget.idObra,
          idUsuario: widget.idUsuario,
          idRol: 2, // Rol Técnico
          isEmbedded: true,
        );
      case 2:
        return SolicitudesObrerosView(
          idObra: widget.idObra,
          idTecnicoUsuario: widget.idUsuario,
          isEmbedded: true,
        );
      case 3:
        return HistorialTecnicoView(
          idObra: widget.idObra,
          isEmbedded: true,
        );
      case 4:
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
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badge pendiente(s)',
                              style: const TextStyle(
                                color: AppColors.surface,
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
        await _cargarDatos();
        await _cargarConteo();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de bienvenida Técnico
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
                          Icons.construction_outlined,
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
                              _nombreTecnico.isNotEmpty
                                  ? '¡Hola, $_nombreTecnico!'
                                  : '¡Bienvenido!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Rol: Técnico de Obra',
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

            // Tarjeta 1: Pisos de la Obra
            _buildMenuCard(
              icon: Icons.layers_outlined,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.12),
              title: 'Pisos de la Obra',
              subtitle:
                  'Consulta los niveles de esta obra y gestiona o solicita material.',
              onTap: () => _cambiarVista(1),
            ),

            const SizedBox(height: 12),

            // Tarjeta 2: Solicitud de Materiales
            _buildMenuCard(
              icon: Icons.pending_actions,
              iconColor: Colors.orange.shade800,
              iconBgColor: Colors.orange.shade50,
              title: 'Solicitud de Materiales',
              subtitle:
                  'Revisa, edita cantidades, aprueba o rechaza pedidos de obreros.',
              badge: _conteoPendientes,
              onTap: () => _cambiarVista(2),
            ),

            const SizedBox(height: 12),

            // Tarjeta 3: Historial de la Obra
            _buildMenuCard(
              icon: Icons.history,
              iconColor: Colors.indigo.shade600,
              iconBgColor: Colors.indigo.shade50,
              title: 'Historial de la Obra',
              subtitle:
                  'Consulta todas las solicitudes procesadas y pedidos a compras.',
              onTap: () => _cambiarVista(3),
            ),

            const SizedBox(height: 12),

            // Tarjeta 4: Mi Perfil
            _buildMenuCard(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF5A7A8A),
              iconBgColor: Colors.blueGrey.shade50,
              title: 'Mi Perfil',
              subtitle:
                  'Consulta y edita tus datos de usuario y credenciales.',
              onTap: () => _cambiarVista(4),
            ),
          ],
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
      body: _getVista(_selectedIndex),
    );
  }
}
