// lib/modules/auth/view/login_view.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../controller/auth_controller.dart';
import '../../../models/usuario_obra_model.dart';
import 'registro_view.dart';

// Pantalla obrero
import '../../usuario/view/obrero_home_view.dart';
// Pantalla gerente
import '../../obra/view/gerente_home_view.dart';

// Paleta de colores personalizada
class _ByggerColors {
  static const Color azulClaro = Color(0xFF6FC6EE);
  static const Color azulMedio = Color(0xFF2FA9E0);
  static const Color azulOscuro = Color(0xFF1D7FAE);
  static const Color fondoClaro = Color(0xFFF4FAFE);
  static const Color textoOscuro = Color(0xFF1E2A32);
  static const Color textoGris = Color(0xFF7C8A93);
  //static const Color fondoOscuro = Color(0xFF121212);
  //static const Color cardOscuro = Color(0xFF1E1E1E);
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AuthController _authController = AuthController();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _isDarkMode = false;

  // Animaciones
  late final AnimationController _animController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _textoFade;
  late final Animation<Offset> _textoSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
          ),
        );

    _textoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _textoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
          ),
        );

    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    final mensaje = await _authController.iniciarSesion(
      correo: _correoController.text,
      contrasena: _contrasenaController.text,
    );

    if (!mounted) return;

    setState(() {
      _cargando = false;
    });

    // Si hubo un error al iniciar sesión
    if (mensaje != null) {
      _mostrarMensaje(mensaje);
      return;
    }

    // ============================================================
    // OBTENER OBRAS Y ROLES DEL USUARIO
    // ============================================================

    try {
      final relaciones = await _authController.obtenerObrasUsuario();

      if (!mounted) return;

      // No tiene ninguna obra asignada
      if (relaciones.isEmpty) {
        _mostrarMensaje('Tu usuario todavía no está asignado a ninguna obra');
        return;
      }

      // ============================================================
      // POR AHORA: UNA SOLA OBRA
      // ============================================================

      if (relaciones.length == 1) {
        final UsuarioObraModel relacion = relaciones.first;

        if (relacion.idRol == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ObreroHomeView()),
          );
        } else if (relacion.idRol == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GerenteHomeView()),
          );
        } else {
          _mostrarMensaje(
            'El rol asignado todavía no tiene una pantalla configurada',
          );
        }

        return;
      }

      // ============================================================
      // MÁS DE UNA OBRA
      // ============================================================

      _mostrarMensaje('Tienes varias obras asignadas. Debes seleccionar una.');
    } catch (e) {
      _mostrarMensaje('No se pudo obtener la información del usuario');
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(color: Colors.white)),
        backgroundColor: _isDarkMode
            ? Colors.grey[850]
            : _ByggerColors.azulOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ====== CONSTRUIR LOGO CON DOS VERSIONES ======
  Widget _buildLogo() {
    // Elegir el logo según el modo
    final String logoPath = _isDarkMode
        ? 'assets/images/logo.png' // Logo para modo oscuro
        : 'assets/images/logoClaroo.png'; // Logo para modo claro

    return Image.asset(
      logoPath,
      height: 110,
      width: 110,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Si no encuentra el logo específico, intenta con el otro o muestra fallback
        print('Error al cargar logo: $error');
        return _buildLogoFallback();
      },
    );
  }

  // ====== LOGO DE RESPALDO (si no encuentra las imágenes) ======
  Widget _buildLogoFallback() {
    // Fallback también cambia según el modo
    return Container(
      height: 110,
      width: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [Colors.grey[700]!, Colors.grey[900]!]
              : [_ByggerColors.azulMedio, _ByggerColors.azulOscuro],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : _ByggerColors.azulOscuro.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'BYGGER',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ====== CONSTRUIR CAMPO DE TEXTO ======
  Widget _buildCampo({
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
      style: TextStyle(
        color: _isDarkMode ? Colors.white : _ByggerColors.textoOscuro,
        fontSize: 16,
      ),
      cursorColor: _ByggerColors.azulMedio,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDarkMode ? Colors.grey[400] : _ByggerColors.textoGris,
        ),
        prefixIcon: Icon(
          icon,
          color: _isDarkMode
              ? _ByggerColors.azulClaro
              : _ByggerColors.azulMedio,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : _ByggerColors.fondoClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _isDarkMode
                ? _ByggerColors.azulMedio.withValues(alpha: 0.3)
                : _ByggerColors.azulClaro.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _ByggerColors.azulMedio,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                  ],
                  stops: [0.0, 0.4, 0.8],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _ByggerColors.azulMedio,
                    _ByggerColors.azulClaro,
                    _ByggerColors.fondoClaro,
                  ],
                  stops: [0.0, 0.35, 0.75],
                ),
        ),
        child: Stack(
          children: [
            // Fondo de construcción
            CustomPaint(
              painter: _ConstructionPainter(isDarkMode: _isDarkMode),
              size: Size.infinite,
            ),

            // Burbujas decorativas
            Positioned(
              top: -60,
              right: -50,
              child: _burbuja(
                180,
                _isDarkMode
                    ? Colors.blueGrey.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 90,
              left: -70,
              child: _burbuja(
                140,
                _isDarkMode
                    ? Colors.blueGrey.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: _burbuja(
                120,
                _isDarkMode
                    ? Colors.blueGrey.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),

            // Botón de cambio de tema
            Positioned(
              top: 20,
              right: 20,
              child: _ThemeToggleButton(
                isDarkMode: _isDarkMode,
                onToggle: _toggleTheme,
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.02),

                        // LOGO - Cambia según el tema
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isDarkMode
                                                  ? Colors.black
                                                  : _ByggerColors.azulOscuro)
                                              .withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: _buildLogo(), // ← Logo dinámico
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Texto de bienvenida
                        FadeTransition(
                          opacity: _textoFade,
                          child: SlideTransition(
                            position: _textoSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Bienvenido de nuevo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ingresa tus datos para continuar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Tarjeta del formulario
                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: Container(
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_isDarkMode
                                                ? Colors.black
                                                : _ByggerColors.azulOscuro)
                                            .withValues(alpha: 0.18),
                                    blurRadius: 30,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildCampo(
                                      controller: _correoController,
                                      label: 'Correo electrónico',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Ingresa tu correo';
                                        }
                                        if (!value.contains('@') ||
                                            !value.contains('.')) {
                                          return 'Correo inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _buildCampo(
                                      controller: _contrasenaController,
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline,
                                      obscureText: _ocultarContrasena,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _ocultarContrasena
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _isDarkMode
                                              ? Colors.grey[400]
                                              : _ByggerColors.textoGris,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _ocultarContrasena =
                                                !_ocultarContrasena;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ingresa tu contraseña';
                                        }
                                        if (value.length < 6) {
                                          return 'Mínimo 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    _BotonAnimado(
                                      cargando: _cargando,
                                      onPressed: _iniciarSesion,
                                      isDarkMode: _isDarkMode,
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () {
                                        _mostrarMensaje(
                                          'Función en desarrollo\n'
                                          'Pronto podrás recuperar tu contraseña',
                                        );
                                      },
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? _ByggerColors.azulClaro
                                              : _ByggerColors.azulMedio,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _cargando
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const RegistroView(),
                                                ),
                                              );
                                            },
                                      child: Text(
                                        '¿No tienes una cuenta? Regístrate',
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? _ByggerColors.azulClaro
                                              : _ByggerColors.azulMedio,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        FadeTransition(
                          opacity: _cardFade,
                          child: Text(
                            'BYGGER SRL · Constructora',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : _ByggerColors.textoOscuro,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _burbuja(double tamano, Color color) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ====== BOTÓN DE CAMBIO DE TEMA ======
class _ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const _ThemeToggleButton({required this.isDarkMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode ? Colors.amber[300] : Colors.grey[700],
            size: 26,
          ),
          onPressed: onToggle,
          tooltip: isDarkMode
              ? 'Cambiar a modo claro'
              : 'Cambiar a modo oscuro',
          splashRadius: 24,
        ),
      ),
    );
  }
}

// ====== BOTÓN DE INICIO DE SESIÓN CON ANIMACIÓN ======
class _BotonAnimado extends StatefulWidget {
  final bool cargando;
  final VoidCallback onPressed;
  final bool isDarkMode;

  const _BotonAnimado({
    required this.cargando,
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  State<_BotonAnimado> createState() => _BotonAnimadoState();
}

class _BotonAnimadoState extends State<_BotonAnimado> {
  double _escala = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _escala = 0.96);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _escala = 1.0);
  }

  void _onTapCancel() {
    setState(() => _escala = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.cargando ? null : _onTapDown,
      onTapUp: widget.cargando ? null : _onTapUp,
      onTapCancel: widget.cargando ? null : _onTapCancel,
      onTap: widget.cargando ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _escala,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.cargando
                ? LinearGradient(
                    colors: widget.isDarkMode
                        ? [Colors.grey[700]!, Colors.grey[800]!]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  )
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_ByggerColors.azulMedio, _ByggerColors.azulOscuro],
                  ),
            boxShadow: widget.cargando
                ? []
                : [
                    BoxShadow(
                      color: _ByggerColors.azulOscuro.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.cargando
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ====== PAINTER PARA FONDO DE CONSTRUCCIÓN ======
class _ConstructionPainter extends CustomPainter {
  final bool isDarkMode;

  _ConstructionPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.03)
          : Colors.blueGrey.withValues(alpha: 0.04);

    final random = Random(42);
    final double ancho = size.width;
    final double alto = size.height;

    // Líneas de construcción
    for (int i = 0; i < 25; i++) {
      final double x = random.nextDouble() * ancho;
      final double y = random.nextDouble() * alto;
      final double angulo = random.nextDouble() * 2 * pi;

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.05 + random.nextDouble() * 0.08)
          : Colors.blueGrey.withValues(
              alpha: 0.03 + random.nextDouble() * 0.06,
            );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angulo);

      canvas.drawLine(
        const Offset(-20, 0),
        const Offset(20, 0),
        paint..strokeWidth = 1.5,
      );

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.08)
          : Colors.blueGrey.withValues(alpha: 0.06);
      canvas.drawCircle(const Offset(-20, 0), 2, paint);
      canvas.drawCircle(const Offset(20, 0), 2, paint);

      canvas.restore();
    }

    // Cuadrados de construcción
    for (int i = 0; i < 12; i++) {
      final double x = random.nextDouble() * ancho;
      final double y = random.nextDouble() * alto;
      final double lado = 20 + random.nextDouble() * 50;
      final double angulo = random.nextDouble() * 2 * pi;

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.04 + random.nextDouble() * 0.06)
          : Colors.blueGrey.withValues(
              alpha: 0.03 + random.nextDouble() * 0.05,
            );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angulo);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: lado, height: lado),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint..style = PaintingStyle.stroke);

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.04)
          : Colors.blueGrey.withValues(alpha: 0.03);

      canvas.drawLine(
        Offset(-lado / 3, -lado / 2),
        Offset(-lado / 3, lado / 2),
        paint..strokeWidth = 0.5,
      );
      canvas.drawLine(
        Offset(lado / 3, -lado / 2),
        Offset(lado / 3, lado / 2),
        paint..strokeWidth = 0.5,
      );
      canvas.drawLine(
        Offset(-lado / 2, -lado / 3),
        Offset(lado / 2, -lado / 3),
        paint..strokeWidth = 0.5,
      );
      canvas.drawLine(
        Offset(-lado / 2, lado / 3),
        Offset(lado / 2, lado / 3),
        paint..strokeWidth = 0.5,
      );

      canvas.restore();
    }

    // Círculos decorativos
    for (int i = 0; i < 6; i++) {
      final double x = random.nextDouble() * ancho;
      final double y = random.nextDouble() * alto;
      final double radio = 30 + random.nextDouble() * 50;

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.02)
          : Colors.blueGrey.withValues(alpha: 0.015);

      canvas.drawCircle(Offset(x, y), radio, paint);

      paint.color = isDarkMode
          ? Colors.blueGrey.withValues(alpha: 0.03)
          : Colors.blueGrey.withValues(alpha: 0.02);
      canvas.drawCircle(
        Offset(x, y),
        radio * 0.5,
        paint..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(x, y),
        radio * 1.5,
        paint..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
