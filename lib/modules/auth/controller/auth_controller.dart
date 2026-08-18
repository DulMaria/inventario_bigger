import '../service/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _authService.iniciarSesion(correo: correo, contrasena: contrasena);

      return true;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return false;
    }
  }

  Future<int?> obtenerRolUsuario() async {
    return await _authService.obtenerRolUsuario();
  }

  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
  }
}
