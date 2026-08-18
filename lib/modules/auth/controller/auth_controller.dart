import '../service/auth_service.dart';
import '../../../models/usuario_obra_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    // =========================
    // VALIDACIONES DEL CORREO
    // =========================

    if (correo.trim().isEmpty) {
      return 'Ingresa tu correo';
    }

    // No permitir espacios
    if (correo.contains(' ')) {
      return 'El correo no debe contener espacios';
    }

    // Validar estructura del correo
    final correoValido = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!correoValido.hasMatch(correo.trim())) {
      return 'Ingresa un correo válido, por ejemplo: usuario@gmail.com';
    }

    // =========================
    // VALIDACIONES CONTRASEÑA
    // =========================

    if (contrasena.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    // =========================
    // INICIAR SESIÓN
    // =========================

    try {
      await _authService.iniciarSesion(
        correo: correo.trim(),
        contrasena: contrasena,
      );

      return null;
    } catch (e) {
      print('Error al iniciar sesión: $e');

      return 'Correo o contraseña incorrectos';
    }
  }

  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    return await _authService.obtenerObrasUsuario();
  }

  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
  }
}
