import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
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
  final _respuestaController = TextEditingController();
  final _preguntaPersonalizadaController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _ocultarConfirmacion = true;

  String? _preguntaSeleccionada;
  final List<String> _opcionesPreguntas = [
    '¿Cuál fue el nombre de tu primera mascota?',
    '¿En qué ciudad nació tu madre?',
    '¿Cuál es el nombre de tu colegio primario?',
    '¿Cuál es tu color favorito?',
    '¿Cuál es tu comida favorita?',
    'Escribir mi propia pregunta...',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _respuestaController.dispose();
    _preguntaPersonalizadaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_preguntaSeleccionada == null) {
      _mostrarMensaje('Por favor, selecciona una pregunta de seguridad');
      return;
    }

    String preguntaFinal = _preguntaSeleccionada!;

    // Si elige escribir su propia pregunta, la procesamos
    if (_preguntaSeleccionada == 'Escribir mi propia pregunta...') {
      final custom = _preguntaPersonalizadaController.text.trim();
      if (custom.isEmpty) {
        _mostrarMensaje('Por favor, escribe tu propia pregunta');
        return;
      }
      // Quitamos signos existentes para evitar dobles, y envolvemos en ¿ ?
      final textoLimpio = custom.replaceAll('¿', '').replaceAll('?', '').trim();
      preguntaFinal = '¿$textoLimpio?';
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
      preguntaSeguridad: preguntaFinal,
      respuestaSeguridad: _respuestaController.text,
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
        content: Text(texto, style: const TextStyle(color: AppColors.surface)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Crear cuenta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.surface,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primary, AppColors.backgroundLight],
            stops: [0.0, 0.35, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D7FAE).withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7C8A93),
                          ),
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
                            if (RegExp(r'(.)\1{3,}').hasMatch(value)) {
                              return 'No se permiten caracteres repetidos (ej. kkkk)';
                            }
                            if (RegExp(r'[^a-zA-Z0-9\sñÑáéíóúÁÉÍÓÚ]').hasMatch(value)) {
                              return 'No se permiten caracteres especiales';
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
                            if (RegExp(r'(.)\1{3,}').hasMatch(value)) {
                              return 'No se permiten caracteres repetidos (ej. kkkk)';
                            }
                            if (RegExp(r'[^a-zA-Z0-9\sñÑáéíóúÁÉÍÓÚ]').hasMatch(value)) {
                              return 'No se permiten caracteres especiales';
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
                            if (value.length > 8) {
                              return 'Máximo 8 caracteres';
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

                        const SizedBox(height: 16),

                        // Selector de Pregunta de Seguridad
                        DropdownButtonFormField<String>(
                          value: _preguntaSeleccionada,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          dropdownColor: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 4,
                          hint: const Text(
                            'Selecciona o escribe una pregunta...',
                            style: TextStyle(
                              color: Color(0xFF7C8A93),
                              fontSize: 14,
                            ),
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                          items: _opcionesPreguntas.map((String pregunta) {
                            final bool esPersonalizada =
                                pregunta == 'Escribir mi propia pregunta...';
                            return DropdownMenuItem<String>(
                              value: pregunta,
                              child: Row(
                                children: [
                                  Icon(
                                    esPersonalizada
                                        ? Icons.edit_note_rounded
                                        : Icons.help_outline_rounded,
                                    size: 20,
                                    color: esPersonalizada
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      pregunta,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: esPersonalizada
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: esPersonalizada
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? nuevoValor) {
                            setState(() {
                              _preguntaSeleccionada = nuevoValor;
                            });
                          },
                        ),

                        if (_preguntaSeleccionada ==
                            'Escribir mi propia pregunta...') ...[
                          const SizedBox(height: 16),
                          _campo(
                            controller: _preguntaPersonalizadaController,
                            label: 'Escribe tu pregunta secreta',
                            icon: Icons.edit_note,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu pregunta';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Respuesta de Seguridad
                        _campo(
                          controller: _respuestaController,
                          label: 'Tu respuesta secreta',
                          icon: Icons.question_answer_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu respuesta';
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
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
                                      color: AppColors.surface,
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
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
