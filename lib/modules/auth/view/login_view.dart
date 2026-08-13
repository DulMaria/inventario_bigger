import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';

// Pantalla obrero
import '../../usuario/view/obrero_home_view.dart';
// Pantalla gerente
import '../../obra/view/gerente_home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _cargando = false;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
    });

    final resultado = await _authController.iniciarSesion(
      correo: _correoController.text.trim(),
      contrasena: _contrasenaController.text,
    );

    setState(() {
      _cargando = false;
    });

    if (!mounted) return;

    if (resultado) {
      final rol = await _authController.obtenerRolUsuario();

      if (!mounted) return;

      if (rol == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ObreroHomeView(),
          ),
        );
      } else if (rol == 3) {
        // Gerente
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GerenteHomeView(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol no configurado todavía'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña incorrectos'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _contrasenaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}