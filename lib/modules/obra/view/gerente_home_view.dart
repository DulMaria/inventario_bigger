import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';
import 'proformas_gerente_view.dart';
import 'usuarios_por_obra_view.dart';
import '../../../models/obra_model.dart';

class GerenteHomeView extends StatefulWidget {
  final int? idObra;
  final int? idUsuario;
  final String? nombreObra;

  const GerenteHomeView({
    super.key,
    this.idObra,
    this.idUsuario,
    this.nombreObra,
  });

  @override
  State<GerenteHomeView> createState() => _GerenteHomeViewState();
}

class _GerenteHomeViewState extends State<GerenteHomeView> {
  int _selectedIndex = 0;
  String _nombreGerente = '';
  
  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
      _menuItems = [
        {'icon': Icons.dashboard, 'title': 'Dashboard'},
        {'icon': Icons.people, 'title': 'Usuarios de Obra'},
        {'icon': Icons.person_add_alt_1, 'title': 'Solicitudes de Acceso'},
        {'icon': Icons.receipt_long, 'title': 'Proformas Llegadas'},
        {'icon': Icons.person, 'title': 'Mi Perfil'},
      ];
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
        String fetchedNombre = '';
        final data = await Supabase.instance.client
            .from('usuarios')
            .select('nombre, apellido')
            .eq('id_auth', user.id)
            .maybeSingle();
            
        if (data != null) {
          final nombre = data['nombre'] ?? '';
          final apellido = data['apellido'] ?? '';
          fetchedNombre = '$nombre $apellido'.trim();
        }
        
        if (fetchedNombre.isEmpty) {
          final meta = user.userMetadata;
          if (meta != null) {
            fetchedNombre = '${meta['nombre'] ?? ''} ${meta['apellido'] ?? ''}'.trim();
          }
        }
        
        if (fetchedNombre.isEmpty && user.email != null) {
          fetchedNombre = user.email!.split('@').first;
        }

        if (mounted) {
          setState(() {
            _nombreGerente = fetchedNombre;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos del gerente: $e');
    }
  }

  Widget _getVista(int index) {
    switch (index) {
      case 0:
        return _buildDashboardView();
      case 1:
        return UsuariosPorObraView(
          obra: ObraModel(
            idObra: widget.idObra ?? 0,
            nombre: widget.nombreObra ?? '',
            estado: true,
          ),
        );
      case 2:
        return SolicitudesAccesoView(
          idObra: widget.idObra,
          nombreObra: widget.nombreObra,
          isEmbedded: true,
        );
      case 3:
        return ProformasGerenteView(
          idObra: widget.idObra ?? 0,
          idUsuarioGerente: widget.idUsuario ?? 0,
          nombreObra: widget.nombreObra,
          isEmbedded: true,
        );
      case 4:
        return const PerfilUsuarioView(isEmbedded: true);
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final paddingHorizontal = isSmallScreen ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de Bienvenida Adaptable
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      Colors.indigo.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreGerente.isNotEmpty 
                        ? '👋 ¡Bienvenido $_nombreGerente!'
                        : '👋 ¡Bienvenido, Gerente!',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.nombreObra != null 
                        ? 'Gerente asignado a la obra: "${widget.nombreObra}"'
                        : 'Gestión y control general de la obra',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tarjeta 1: Solicitudes de Acceso (Redirige a SolicitudesAccesoView - Index 2)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  leading: Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1,
                      color: AppColors.primary,
                      size: isSmallScreen ? 22 : 24,
                    ),
                  ),
                  title: Text(
                    'Solicitudes de Acceso',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    widget.nombreObra != null
                        ? 'Revisar y autorizar accesos para ${widget.nombreObra}'
                        : 'Revisar y autorizar solicitudes de acceso a la obra',
                    style: TextStyle(
                      color: const Color(0xFF7C8A93),
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _cambiarVista(2),
                ),
              ),

              const SizedBox(height: 12),

              // Tarjeta 2: Proformas Llegadas (Redirige a ProformasGerenteView - Index 3)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  leading: Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.amber.shade800,
                      size: isSmallScreen ? 22 : 24,
                    ),
                  ),
                  title: Text(
                    'Proformas Llegadas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    'Revisión y autorización de cotizaciones y proformas enviadas por compras.',
                    style: TextStyle(
                      color: const Color(0xFF7C8A93),
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _cambiarVista(3),
                ),
              ),

              const SizedBox(height: 12),

              // Tarjeta 3: Usuarios de Obra (Redirige a UsuariosPorObraView - Index 1)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  leading: Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people,
                      color: Colors.blue.shade700,
                      size: isSmallScreen ? 22 : 24,
                    ),
                  ),
                  title: Text(
                    'Usuarios de Obra',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    'Ver lista de obreros, técnicos y personal asignado a la obra.',
                    style: TextStyle(
                      color: const Color(0xFF7C8A93),
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _cambiarVista(1),
                ),
              ),
            ],
          ),
        );
      },
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
