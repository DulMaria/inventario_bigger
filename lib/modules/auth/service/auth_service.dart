import '../../../models/usuario_obra_model.dart';
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

  Future<AuthResponse> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombre,
    required String apellido,
    String? telefono,
  }) async {
    final respuesta = await _supabase.auth.signUp(
      email: correo,
      password: contrasena,
      data: {'nombre': nombre, 'apellido': apellido, 'telefono': telefono},
    );

    if (respuesta.user == null) {
      throw Exception('No se pudo crear la cuenta');
    }

    return respuesta;
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  User? get usuarioActual => _supabase.auth.currentUser;

  // Obtener las obras a las que pertenece el usuario
  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return [];
    }

    final usuarioBD = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuario.id)
        .maybeSingle();

    if (usuarioBD == null) {
      return [];
    }

    final idUsuario = usuarioBD['id_usuario'] as int;

    final respuesta = await _supabase
        .from('usuario_obra')
        .select()
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    return (respuesta as List)
        .map((item) => UsuarioObraModel.fromMap(item))
        .toList();
  }
}
