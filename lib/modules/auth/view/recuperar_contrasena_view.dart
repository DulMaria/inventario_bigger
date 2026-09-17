import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';

class _ByggerColors {
  static const Color azulMedio = Color(0xFF2FA9E0);
  static const Color azulOscuro = Color(0xFF1D7FAE);
  static const Color fondoClaro = Color(0xFFF4FAFE);
  static const Color textoOscuro = Color(0xFF1E2A32);
  static const Color textoGris = Color(0xFF7C8A93);
}

class RecuperarContrasenaView extends StatefulWidget {
  final String telefonoInicial;

  const RecuperarContrasenaView({super.key, this.telefonoInicial = ''});

  @override
  State<RecuperarContrasenaView> createState() =>
      _RecuperarContrasenaViewState();
}

class _RecuperarContrasenaViewState extends State<RecuperarContrasenaView> {
  final _telefonoController = TextEditingController();
  final _respuestaController = TextEditingController();
  final _contrasenaController = TextEditingController();

  final _authController = AuthController();

  bool _cargando = false;
  int _pasoActual = 1; // 1: Teléfono, 2: Pregunta y Nueva Contraseña
  bool _ocultarContrasena = true;
  String? _preguntaRecuperada;

  @override
  void initState() {
    super.initState();
    _telefonoController.text = widget.telefonoInicial;
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _respuestaController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(color: Colors.white)),
        backgroundColor: exito ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // PASO 1
  Future<void> _buscarPregunta() async {
    final telefono = _telefonoController.text.trim();
    if (telefono.isEmpty) {
      _mostrarMensaje('Por favor, ingresa tu número');
      return;
    }

    setState(() => _cargando = true);
    final pregunta = await _authController.obtenerPreguntaSeguridad(telefono);
    setState(() => _cargando = false);

    if (pregunta != null) {
      setState(() {
        _preguntaRecuperada = pregunta;
        _pasoActual = 2;
      });
    } else {
      _mostrarMensaje(
        'No se encontró cuenta con este número o no tiene pregunta de seguridad.',
      );
    }
  }

  // PASO 2
  Future<void> _cambiarContrasena() async {
    setState(() => _cargando = true);
    final error = await _authController.recuperarContrasenaPorPregunta(
      telefono: _telefonoController.text,
      respuesta: _respuestaController.text,
      nuevaContrasena: _contrasenaController.text,
    );
    setState(() => _cargando = false);

    if (error != null) {
      _mostrarMensaje(error);
    } else {
      _mostrarMensaje('Contraseña actualizada con éxito', exito: true);
      if (mounted) {
        Navigator.pop(context); // Volver al login
      }
    }
  }

  Widget _buildBoton(String texto, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _ByggerColors.azulMedio,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _cargando ? null : onPressed,
        child: _cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2FA9E0), // _ByggerColors.azulMedio
              Color(0xFF6FC6EE), // _ByggerColors.azulClaro
              Color(0xFFF4FAFE), // _ByggerColors.fondoClaro
            ],
            stops: [0.0, 0.35, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D7FAE).withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        size: 64,
                        color: _ByggerColors.azulMedio,
                      ),
                      const SizedBox(height: 16),

                      if (_pasoActual == 1) ...[
                        const Text(
                          'Ingresa tu número de celular para buscar tu pregunta de seguridad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _ByggerColors.textoGris),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Número de celular',
                            prefixIcon: const Icon(Icons.phone_android),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBoton('Buscar Cuenta', _buscarPregunta),
                      ],

                      if (_pasoActual == 2) ...[
                        const Text(
                          'Responde tu pregunta de seguridad para crear una nueva contraseña.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _ByggerColors.textoGris),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _ByggerColors.fondoClaro,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _ByggerColors.azulMedio.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            _preguntaRecuperada ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _respuestaController,
                          decoration: InputDecoration(
                            labelText: 'Tu respuesta secreta',
                            prefixIcon: const Icon(Icons.question_answer),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _contrasenaController,
                          obscureText: _ocultarContrasena,
                          decoration: InputDecoration(
                            labelText: 'Nueva Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarContrasena
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _ocultarContrasena = !_ocultarContrasena,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBoton('Cambiar Contraseña', _cambiarContrasena),
                        TextButton(
                          onPressed: () => setState(() => _pasoActual = 1),
                          child: const Text('Volver atrás'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
