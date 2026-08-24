import 'package:flutter/material.dart';

import 'obra_view.dart';

import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';

class GerenteHomeView extends StatelessWidget {
  const GerenteHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel del Gerente'), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text('Seleccione una opción', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 30),

            // ============================================
            // VER OBRAS
            // ============================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.business),

                title: const Text('Gestión de Obras'),

                subtitle: const Text('Visualizar, crear y editar obras'),

                trailing: const Icon(Icons.arrow_forward_ios),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ObrasView()),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ============================================
            // SOLICITUDES DE ACCESO
            // ============================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add_alt_1),

                title: const Text('Solicitudes'),

                subtitle: const Text(
                  'Revisar solicitudes de acceso a las obras',
                ),

                trailing: const Icon(Icons.arrow_forward_ios),

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
          ],
        ),
      ),
    );
  }
}
