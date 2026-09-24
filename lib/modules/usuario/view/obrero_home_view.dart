import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import 'package:inventario_bigger/modules/piso/view/piso_obrero_view.dart'
    show PisosObraView;
import 'Obrero/historial_solicitudes_obrero_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';

class ObreroHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final String? nombreObra;

  const ObreroHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.nombreObra,
  });

  @override
  State<ObreroHomeView> createState() => _ObreroHomeViewState();
}

class _ObreroHomeViewState extends State<ObreroHomeView> {
  int _selectedIndex = 0;
  String _nombreObrero = '';
  String _nombreObra = '';

  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _nombreObra = widget.nombreObra ?? 'Cargando obra...';
    _menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.layers_outlined, 'title': 'Pisos de la Obra'},
      {'icon': Icons.history, 'title': 'Historial de Solicitudes'},
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Cargar nombre del usuario
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
              _nombreObrero = '$nombre $apellido'.trim();
            });
          }
        }
      }

      // Cargar nombre de la obra si no venía o para confirmar
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
      debugPrint('Error al cargar datos del obrero: $e');
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
          isEmbedded: true,
        );
      case 2:
        return HistorialSolicitudesObreroView(
          idObra: widget.idObra,
          idUsuario: widget.idUsuario,
          isEmbedded: true,
        );
      case 3:
        return const PerfilUsuarioView(isEmbedded: true);
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de bienvenida similar al del Gerente
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
                        Icons.engineering_outlined,
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
                            _nombreObrero.isNotEmpty
                                ? '¡Hola, $_nombreObrero!'
                                : '¡Bienvenido!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Rol: Obrero de Obra',
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
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),

          const SizedBox(height: 14),

          // Tarjeta Pisos de la Obra
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _cambiarVista(1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.layers_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pisos de la Obra',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Explora los niveles de la obra y solicita materiales necesarios.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7C8A93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF7C8A93),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tarjeta Historial de Solicitudes
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _cambiarVista(2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.amber.shade800,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historial de Solicitudes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Consulta el estado de aprobación de los pedidos que has enviado.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7C8A93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF7C8A93),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tarjeta Mi Perfil
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _cambiarVista(3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF5A7A8A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi Perfil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Consulta y edita tus datos de usuario y credenciales.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7C8A93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF7C8A93),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
