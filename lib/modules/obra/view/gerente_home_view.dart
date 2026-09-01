import 'package:flutter/material.dart';

import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';
import '../../solicitud_acceso/view/seleccionar_obra_view.dart';

class GerenteHomeView extends StatelessWidget {
  const GerenteHomeView({super.key});

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
        title: const Text('Panel del Gerente'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido, Gerente',
              style: TextStyle(
                fontSize: 24,
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
                subtitle: const Text(
                  'Revisar y autorizar solicitudes de acceso a las obras',
                  style: TextStyle(color: Color(0xFF7C8A93)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SolicitudesAccesoView(),
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
