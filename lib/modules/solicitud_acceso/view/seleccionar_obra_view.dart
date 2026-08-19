import 'package:flutter/material.dart';

import '../../../models/obra_model.dart';
import '../controller/solicitud_acceso_controller.dart';
import 'seleccionar_rol_view.dart';

class SeleccionarObraView extends StatefulWidget {
  const SeleccionarObraView({super.key});

  @override
  State<SeleccionarObraView> createState() => _SeleccionarObraViewState();
}

class _SeleccionarObraViewState extends State<SeleccionarObraView> {
  final SolicitudAccesoController _controller = SolicitudAccesoController();

  List<ObraModel> _obras = [];
  ObraModel? _obraSeleccionada;

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  Future<void> _cargarObras() async {
    setState(() {
      _cargando = true;
    });

    try {
      final obras = await _controller.obtenerObrasDisponibles();

      if (!mounted) {
        return;
      }

      setState(() {
        _obras = obras;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
      });

      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _continuar() async {
    if (_obraSeleccionada == null) {
      _mostrarMensaje('Selecciona una obra para continuar');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarRolView(obra: _obraSeleccionada!),
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D7FAE),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Seleccionar obra'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _obras.isEmpty
          ? _sinObras()
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Selecciona la obra a la que deseas solicitar acceso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2A32),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Después podrás seleccionar el rol con el que deseas ingresar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarObras,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _obras.length,
                      itemBuilder: (context, index) {
                        final obra = _obras[index];

                        final seleccionada =
                            _obraSeleccionada?.idObra == obra.idObra;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: seleccionada ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: seleccionada
                                  ? const Color(0xFF2FA9E0)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: seleccionada
                                  ? const Color(0xFF2FA9E0)
                                  : const Color(0xFFE1F3FC),
                              child: Icon(
                                Icons.business,
                                color: seleccionada
                                    ? Colors.white
                                    : const Color(0xFF2FA9E0),
                              ),
                            ),
                            title: Text(
                              obra.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(obra.direccion ?? 'Sin dirección'),
                            ),
                            trailing: Radio<int>(
                              value: obra.idObra,
                              groupValue: _obraSeleccionada?.idObra,
                              activeColor: const Color(0xFF2FA9E0),
                              onChanged: (_) {
                                setState(() {
                                  _obraSeleccionada = obra;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _obraSeleccionada = obra;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _obraSeleccionada == null ? null : _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA9E0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sinObras() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 70,
              color: Color(0xFF2FA9E0),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay obras disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A32),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No existen obras a las que puedas solicitar acceso en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _cargarObras,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
