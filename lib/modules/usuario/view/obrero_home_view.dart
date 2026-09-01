import 'package:flutter/material.dart';

import 'package:inventario_bigger/modules/piso/view/piso_obrero_view.dart'
    show PisosObraView;
import 'Obrero/historial_solicitudes_obrero_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';

class ObreroHomeView extends StatefulWidget {
  final int idObra;
  final int idUsuario;

  const ObreroHomeView({
    super.key,
    required this.idObra,
    required this.idUsuario,
  });

  @override
  State<ObreroHomeView> createState() => _ObreroHomeViewState();
}

class _ObreroHomeViewState extends State<ObreroHomeView> {
  String nombreObra = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _cargarObra();
  }

  Future<void> _cargarObra() async {
    // Aquí consultaremos la obra usando widget.idObra
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final authController = AuthController();
      await authController.cerrarSesion();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const String nombreObra = 'Obra asignada';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Cambiar de obra',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
            );
          },
        ),
        title: const Text('Inicio'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            const Text(
              'Bienvenido a la obra',
              style: TextStyle(fontSize: 17, color: Color(0xFF7C8A93)),
            ),

            const SizedBox(height: 5),

            const Text(
              nombreObra,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),

            const SizedBox(height: 35),

            _opcion(
              icono: Icons.layers_outlined,
              titulo: 'Pisos de la obra',
              descripcion: 'Consulta los diferentes pisos de esta obra.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PisosObraView(
                      idObra: widget.idObra,
                      idUsuario: widget.idUsuario,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            _opcion(
              icono: Icons.history,
              titulo: 'Historial',
              descripcion:
                  'Consulta el historial de tus solicitudes y actividades.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialSolicitudesObreroView(
                      idObra: widget.idObra,
                      idUsuario: widget.idUsuario,
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

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F3FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF2FA9E0),
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2A32),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7C8A93),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Color(0xFF7C8A93),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
