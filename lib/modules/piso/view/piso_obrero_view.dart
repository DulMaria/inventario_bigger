import 'package:flutter/material.dart';

import '../../../models/piso_model.dart';
import '../../piso/controller/piso_controller.dart';
import '../../material/view/materiales_view.dart';

class PisosObraView extends StatefulWidget {
  final int idObra;
  final int idUsuario;
  final int idRol;

  const PisosObraView({
    super.key,
    required this.idObra,
    required this.idUsuario,
    this.idRol = 1,
  });

  @override
  State<PisosObraView> createState() => _PisosObraViewState();
}

class _PisosObraViewState extends State<PisosObraView> {
  final PisoController _controller = PisoController();

  List<PisoModel> _pisos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPisos();
  }

  Future<void> _cargarPisos() async {
    try {
      final pisos = await _controller.obtenerPisos(widget.idObra);

      if (!mounted) return;

      setState(() {
        _pisos = pisos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.idRol == 2
              ? 'Solicitud Directa de Material'
              : 'Pisos de la obra',
        ),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pisos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 64,
                          color: Color(0xFFB7C5CC),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay pisos registrados en esta obra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aún no se han configurado niveles o pisos para esta obra.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7C8A93)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al inicio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2FA9E0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPisos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pisos.length,
                    itemBuilder: (context, index) {
                      final piso = _pisos[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F3FC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.apartment,
                              color: Color(0xFF2FA9E0),
                            ),
                          ),
                          title: Text(
                            piso.etiquetaNivel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Estado: ${piso.estadoObra}',
                            style: const TextStyle(color: Color(0xFF7C8A93)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F3FC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  piso.tipoPiso,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D7FAE),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF7C8A93),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MaterialesView(
                                  idObra: widget.idObra,
                                  idPiso: piso.idPiso,
                                  idUsuario: widget.idUsuario,
                                  idRol: widget.idRol,
                                  piso: piso,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
