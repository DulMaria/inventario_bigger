import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    Colors.indigo.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _nombreGerente.isNotEmpty 
                        ? '👋 ¡Bienvenido $_nombreGerente, Gerente de la obra "${widget.nombreObra ?? ''}"!'
                        : '👋 ¡Bienvenido, Gerente de la obra "${widget.nombreObra ?? ''}"!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    'Desde aquí puedes gestionar los accesos, revisar proformas llegadas y más.',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 25),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F3FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
              ),
              title: const Text(
                'Solicitudes de Acceso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                widget.nombreObra != null
                    ? 'Revisar y autorizar solicitudes para ${widget.nombreObra}'
                    : 'Revisar y autorizar solicitudes de acceso a la obra',
                style: const TextStyle(color: Color(0xFF7C8A93)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _cambiarVista(1),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: Colors.amber.shade800),
              ),
              title: const Text(
                'Proformas Llegadas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text(
                'Revisión y autorización de cotizaciones y proformas enviadas por compras.',
                style: TextStyle(color: Color(0xFF7C8A93)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _cambiarVista(2),
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
        title: Text(_menuItems[_selectedIndex]['title']),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
