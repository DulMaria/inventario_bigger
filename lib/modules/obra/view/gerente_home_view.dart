import 'package:flutter/material.dart';

import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';

class GerenteHomeView extends StatelessWidget {
  final int? idObra;
  final String? nombreObra;

  const GerenteHomeView({
    super.key,
    this.idObra,
    this.nombreObra,
  });

  Future<void> _cerrarSesion(BuildContext context) async {
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
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a obras',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
            );
          },
        ),
        title: Text(nombreObra != null ? 'Gerente - $nombreObra' : 'Panel del Gerente'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              nombreObra != null ? 'Obra: $nombreObra' : 'Bienvenido, Gerente',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seleccione una opción para gestionar',
              style: TextStyle(fontSize: 15, color: Color(0xFF7C8A93)),
            ),
            const SizedBox(height: 25),

            // ============================================
            // 1. SOLICITUDES DE ACCESO
            // ============================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F3FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Color(0xFF2FA9E0),
                  ),
                ),
                title: const Text(
                  'Solicitudes de Acceso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  nombreObra != null
                      ? 'Revisar y autorizar solicitudes para $nombreObra'
                      : 'Revisar y autorizar solicitudes de acceso a la obra',
                  style: const TextStyle(color: Color(0xFF7C8A93)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SolicitudesAccesoView(
                        idObra: idObra,
                        nombreObra: nombreObra,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ============================================
            // 2. PROFORMAS DE MATERIALES (PRÓXIMAMENTE)
            // ============================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.amber.shade800,
                  ),
                ),
                title: Row(
                  children: [
                    const Text(
                      'Proformas Llegadas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Revisión y aprobación de proformas y cotizaciones enviadas por compras.',
                  style: TextStyle(color: Color(0xFF7C8A93)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF2FA9E0)),
                          SizedBox(width: 8),
                          Text('Módulo en desarrollo'),
                        ],
                      ),
                      content: const Text(
                        'Aquí podrás visualizar y aprobar las proformas y cotizaciones que te envíe el encargado de compras.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
