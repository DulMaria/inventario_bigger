import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/auth_service.dart';
import '../../../models/usuario_obra_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    if (correo.trim().isEmpty) {
      return 'Ingresa tu correo';
    }

    if (correo.contains(' ')) {
      return 'El correo no debe contener espacios';
    }

    final correoValido = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!correoValido.hasMatch(correo.trim())) {
      return 'Ingresa un correo válido, por ejemplo: usuario@gmail.com';
    }

    if (contrasena.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

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

  Future<String?> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombre,
    required String apellido,
    String? telefono,
  }) async {
    if (nombre.trim().isEmpty) {
      return 'Ingresa tu nombre';
    }

    if (apellido.trim().isEmpty) {
      return 'Ingresa tu apellido';
    }

    if (correo.trim().isEmpty) {
      return 'Ingresa tu correo';
    }

    if (correo.contains(' ')) {
      return 'El correo no debe contener espacios';
    }

    final correoValido = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!correoValido.hasMatch(correo.trim())) {
      return 'Ingresa un correo válido';
    }

    if (contrasena.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    try {
      final respuesta = await _authService.registrarUsuario(
        correo: correo.trim(),
        contrasena: contrasena,
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        telefono: telefono?.trim(),
      );

      if (respuesta.user == null) {
        return 'No se pudo crear la cuenta';
      }

      return null;
    } on AuthApiException catch (e) {
      print('Error de Supabase Auth: ${e.code} - ${e.message}');

      if (e.code == 'user_already_exists') {
        return 'Ya existe una cuenta asociada a este correo';
      }

      if (e.code == 'email_exists') {
        return 'Ya existe una cuenta asociada a este correo';
      }

      if (e.code == 'over_email_send_rate_limit') {
        return 'Se realizaron demasiados intentos. Espera unos segundos e inténtalo nuevamente.';
      }

      return 'No se pudo crear la cuenta';
    } catch (e) {
      print('Error al registrar usuario: $e');

      return 'No se pudo completar el registro';
    }
  }

  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    return await _authService.obtenerObrasUsuario();
  }

  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
  }
}
