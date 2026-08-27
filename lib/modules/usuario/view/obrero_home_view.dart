import 'package:flutter/material.dart';

import 'package:inventario_bigger/modules/piso/view/piso_obrero_view.dart'
    show PisosObraView;

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

  @override
  Widget build(BuildContext context) {
    const String nombreObra = 'Obra asignada';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
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
                // Aquí conectaremos la vista de historial.
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
