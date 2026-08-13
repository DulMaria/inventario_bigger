import 'package:flutter/material.dart';

import '../../obra/view/obra_view.dart';

class GerenteHomeView extends StatelessWidget {
  const GerenteHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Gerente'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Seleccione una opción',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Gestión de Obras'),
                subtitle: const Text(
                  'Crear, editar y visualizar obras',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ObrasView(),
                    ),
                  );
                },
              ),
            ),

            // Más adelante podrás agregar:
            //
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.apartment),
            //     title: Text('Gestión de Pisos'),
            //   ),
            // ),
            //
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.inventory),
            //     title: Text('Materiales'),
            //   ),
            // ),
            //
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.people),
            //     title: Text('Usuarios'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}