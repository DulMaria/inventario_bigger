import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _ocultarConfirmacion = true;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();

    final mensaje = await _authController.registrarUsuario(
      correo: correo.isEmpty ? null : correo,
      contrasena: _contrasenaController.text,
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      telefono: telefono,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = false;
    });

    if (mensaje != null) {
      _mostrarMensaje(mensaje);
      return;
    }

    _mostrarMensaje('Usuario registrado correctamente');

    Navigator.pop(context);
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D7FAE),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                const Text(
                  'Crear una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A32),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Completa tus datos para registrarte',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF7C8A93)),
                ),

                const SizedBox(height: 30),

                _campo(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: _apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu apellido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: _telefonoController,
                  label: 'Número de celular',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu número de celular';
                    }
                    if (value.trim().length < 7) {
                      return 'El celular debe tener al menos 7 dígitos';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: _correoController,
                  label: 'Correo electrónico (Opcional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final correoValido = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );

                      if (!correoValido.hasMatch(value.trim())) {
                        return 'Ingresa un correo válido';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: _contrasenaController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _ocultarContrasena,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarContrasena
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarContrasena = !_ocultarContrasena;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }

                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: _confirmarContrasenaController,
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _ocultarConfirmacion,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmacion
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarConfirmacion = !_ocultarConfirmacion;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }

                    if (value != _contrasenaController.text) {
                      return 'Las contraseñas no coinciden';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA9E0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _cargando
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    '¿Ya tienes una cuenta? Inicia sesión',
                    style: TextStyle(color: Color(0xFF2FA9E0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2FA9E0)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6FC6EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2FA9E0), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
