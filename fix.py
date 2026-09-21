import codecs

content = '''import 'package:flutter/material.dart';
import '../../../core/widgets/custom_drawer.dart';
import '../../administrador/view/perfil_usuario_view.dart';
import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import 'proformas_gerente_view.dart';

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
  
  late final List<Map<String, dynamic>> _menuItems;
  late final List<Widget> _vistas;

  @override
  void initState() {
    super.initState();
    
    _menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.person_add_alt_1, 'title': 'Solicitudes de Acceso'},
      {'icon': Icons.receipt_long, 'title': 'Proformas Llegadas'},
      {'icon': Icons.person, 'title': 'Mi Perfil'},
    ];

    _vistas = [
      _buildDashboardView(),
      SolicitudesAccesoView(
        idObra: widget.idObra,
        nombreObra: widget.nombreObra,
        isEmbedded: true,
      ),
      ProformasGerenteView(
        idObra: widget.idObra ?? 0,
        idUsuarioGerente: widget.idUsuario ?? 0,
        nombreObra: widget.nombreObra,
        isEmbedded: true,
      ),
      const PerfilUsuarioView(isEmbedded: true),
    ];
  }

  void _cambiarVista(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.nombreObra != null ? '¡Hola! Eres el Gerente de la obra "\"' : 'Bienvenido, Gerente',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Desde aquí puedes gestionar los accesos, revisar proformas llegadas y más.',
            style: TextStyle(fontSize: 15, color: Color(0xFF7C8A93)),
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
                child: const Icon(Icons.person_add_alt_1, color: Color(0xFF2FA9E0)),
              ),
              title: const Text(
                'Solicitudes de Acceso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                widget.nombreObra != null
                    ? 'Revisar y autorizar solicitudes para \'
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
      backgroundColor: const Color(0xFFF4FAFE),
      drawer: CustomDrawer(
        selectedIndex: _selectedIndex,
        menuItems: _menuItems,
        onItemSelected: _cambiarVista,
      ),
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]['title']),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
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
      body: _vistas[_selectedIndex],
    );
  }
}
'''
with codecs.open('lib/modules/obra/view/gerente_home_view.dart', 'w', 'utf-8') as f:
    f.write(content)
