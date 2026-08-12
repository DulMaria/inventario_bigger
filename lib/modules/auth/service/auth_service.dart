import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: correo,
      password: contrasena,
    );
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  User? get usuarioActual => _supabase.auth.currentUser;

  // Obtener el rol del usuario autenticado
  Future<int?> obtenerRolUsuario() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return null;
    }

    final respuesta = await _supabase
        .from('usuarios')
        .select('id_rol')
        .eq('id_auth', usuario.id)
        .maybeSingle();

    return respuesta?['id_rol'] as int?;
  }
}