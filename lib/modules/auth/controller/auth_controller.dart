import '../../../models/usuario_model.dart';
// lib/modules/auth/controller/auth_controller.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';
import '../../../models/usuario_obra_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  // ============================================================
  // INICIAR SESIÓN
  // ============================================================
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

  // ============================================================
  // REGISTRAR USUARIO
  // ============================================================
  Future<String?> registrarUsuario({
    String? correo,
    required String contrasena,
    required String nombre,
    required String apellido,
    required String telefono,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
  }) async {
    if (nombre.trim().isEmpty) return 'Ingresa tu nombre';
    if (apellido.trim().isEmpty) return 'Ingresa tu apellido';
    if (telefono.trim().isEmpty) return 'Ingresa tu número de celular';
    if (preguntaSeguridad.trim().isEmpty) return 'Selecciona una pregunta de seguridad';
    if (respuestaSeguridad.trim().isEmpty) return 'Escribe tu respuesta de seguridad';

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
        preguntaSeguridad: preguntaSeguridad.trim(),
        respuestaSeguridad: respuestaSeguridad.trim(),
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

  // ============================================================
  // OBTENER OBRAS DEL USUARIO
  // ============================================================
  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    return await _authService.obtenerObrasUsuario();
  }

  // ============================================================
  // OBTENER ID DEL USUARIO
  // ============================================================
  Future<int?> obtenerIdUsuario() async {
    return await _authService.obtenerIdUsuario();
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================
  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
  }

  // ============================================================
  // ✅ NUEVO: VERIFICAR SI ES ADMINISTRADOR
  // ============================================================
  Future<bool> verificarSiEsAdmin() async {
    try {
      return await _authService.esAdministrador();
    } catch (e) {
      print('Error al verificar si es admin: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ NUEVO: OBTENER ROL DEL USUARIO
  // ============================================================
  Future<String?> obtenerRolUsuario() async {
    try {
      return await _authService.obtenerRolUsuario();
    } catch (e) {
      print('Error al obtener rol: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ NUEVO: OBTENER DATOS COMPLETOS DEL USUARIO
  // ============================================================
  
  Future<UsuarioModel?> obtenerUsuarioActual() async {
    return await _authService.obtenerUsuarioActual();
  }
Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    try {
      return await _authService.obtenerDatosUsuario();
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // ============================================================
  // RECUPERAR CONTRASEÑA (PREGUNTAS DE SEGURIDAD)
  // ============================================================
  
  Future<String?> obtenerPreguntaSeguridad(String telefono) async {
    try {
      if (telefono.trim().isEmpty) return null;
      return await _authService.obtenerPreguntaSeguridad(telefono);
    } catch (e) {
      print('Error al obtener pregunta: $e');
      return null;
    }
  }

  Future<String?> recuperarContrasenaPorPregunta({
    required String telefono,
    required String respuesta,
    required String nuevaContrasena,
  }) async {
    try {
      if (respuesta.trim().isEmpty) return 'Ingresa tu respuesta de seguridad';
      if (nuevaContrasena.length < 6) return 'La contraseña debe tener mínimo 6 caracteres';
      
      final exito = await _authService.recuperarContrasenaPorPregunta(
        telefono: telefono,
        respuesta: respuesta,
        nuevaContrasena: nuevaContrasena,
      );

      if (exito) {
        return null; // Todo bien
      } else {
        return 'Respuesta incorrecta. Inténtalo de nuevo.';
      }
    } catch (e) {
      print('Error al recuperar contraseña: $e');
      return 'No se pudo actualizar la contraseña. Revisa tu conexión.';
    }
  }
}