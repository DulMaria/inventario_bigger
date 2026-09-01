import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/auth_service.dart';
import '../../../models/usuario_obra_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> iniciarSesion({
    required String telefono,
    required String contrasena,
  }) async {
    final limpio = telefono.trim();

    if (limpio.isEmpty) {
      return 'Ingresa tu número de celular';
    }

    if (limpio.contains(' ')) {
      return 'No debe contener espacios';
    }

    if (limpio.length < 7) {
      return 'Ingresa un número de celular válido (mínimo 7 dígitos)';
    }

    if (contrasena.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    try {
      await _authService.iniciarSesion(
        telefono: limpio,
        contrasena: contrasena,
      );

      return null;
    } on AuthException catch (e) {
      // ignore: avoid_print
      print('--> [AUTH EXCEPTION] Code: ${e.statusCode} | Msg: ${e.message}');
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        return 'Credenciales inválidas: la contraseña no coincide o el usuario no está registrado en Supabase Auth.';
      }
      return 'Error de autenticación: ${e.message}';
    } catch (e) {
      // ignore: avoid_print
      print('--> [AUTH ERROR] Inesperado: $e');
      return 'Error al iniciar sesión: ${e.toString().replaceFirst("Exception: ", "")}';
    }
  }

  Future<String?> registrarUsuario({
    String? correo,
    required String contrasena,
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    if (nombre.trim().isEmpty) {
      return 'Ingresa tu nombre';
    }

    if (apellido.trim().isEmpty) {
      return 'Ingresa tu apellido';
    }

    if (telefono.trim().isEmpty) {
      return 'Ingresa tu número de celular';
    }

    if (telefono.trim().length < 7) {
      return 'El número de celular debe tener al menos 7 dígitos';
    }

    if (correo != null && correo.trim().isNotEmpty) {
      final correoLimpio = correo.trim();
      if (correoLimpio.contains(' ')) {
        return 'El correo no debe contener espacios';
      }

      final correoValido = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!correoValido.hasMatch(correoLimpio)) {
        return 'Ingresa un correo válido';
      }
    }

    if (contrasena.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    try {
      final respuesta = await _authService.registrarUsuario(
        correo: correo?.trim(),
        contrasena: contrasena,
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        telefono: telefono.trim(),
      );

      if (respuesta.user == null) {
        return 'No se pudo crear la cuenta';
      }

      return null;
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists' || e.code == 'email_exists') {
        return 'Ya existe una cuenta asociada a este usuario/celular';
      }

      if (e.code == 'over_email_send_rate_limit') {
        return 'Se realizaron demasiados intentos. Espera unos segundos e inténtalo nuevamente.';
      }

      return 'No se pudo crear la cuenta: ${e.message}';
    } catch (e) {
      return 'No se pudo completar el registro: ${e.toString().replaceFirst('Exception: ', '')}';
    }
  }

  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    return await _authService.obtenerObrasUsuario();
  }

  Future<int?> obtenerIdUsuario() async {
    return await _authService.obtenerIdUsuario();
  }

  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
  }
}
