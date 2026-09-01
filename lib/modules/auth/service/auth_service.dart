// lib/modules/auth/service/auth_service.dart
import '../../../models/usuario_obra_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // INICIAR SESIÓN CON TELÉFONO + CONTRASEÑA
  // ============================================================
  Future<AuthResponse> iniciarSesion({
    required String telefono,
    required String contrasena,
  }) async {
    final telLimpio = telefono.trim();
    // ignore: avoid_print
    print('--> [AUTH] Iniciando login para: "$telLimpio"');

    // 1. Si el usuario escribió un correo con '@'
    if (telLimpio.contains('@')) {
      // ignore: avoid_print
      print('--> [AUTH] Entrada detectada como correo directo: $telLimpio');
      return await _supabase.auth.signInWithPassword(
        email: telLimpio,
        password: contrasena,
      );
    }

    // 2. Buscar en la base de datos el correo asociado al número de teléfono
    String? emailEncontrado;

    // 2.1 Intentar mediante función RPC segura (evita bloqueos de RLS)
    try {
      final rpcRes = await _supabase.rpc(
        'obtener_correo_por_telefono',
        params: {'p_telefono': telLimpio},
      );
      if (rpcRes != null && rpcRes.toString().isNotEmpty) {
        emailEncontrado = rpcRes.toString();
        // ignore: avoid_print
        print('--> [AUTH] Correo obtenido mediante RPC: $emailEncontrado');
      }
    } catch (e) {
      // ignore: avoid_print
      print('--> [AUTH] RPC no disponible, intentando consulta directa: $e');
    }

    // 2.2 Si RPC no devolvió nada, intentar consulta directa a la tabla usuarios
    if (emailEncontrado == null) {
      try {
        final usuarioBD = await _supabase
            .from('usuarios')
            .select('correo, telefono')
            .eq('telefono', telLimpio)
            .maybeSingle();

        // ignore: avoid_print
        print('--> [AUTH] Consulta tabla usuarios para "$telLimpio": $usuarioBD');

        if (usuarioBD != null &&
            usuarioBD['correo'] != null &&
            (usuarioBD['correo'] as String).isNotEmpty) {
          emailEncontrado = usuarioBD['correo'] as String;
        }
      } catch (e) {
        // ignore: avoid_print
        print('--> [AUTH] Error al consultar tabla usuarios (verificar RLS): $e');
      }
    }

    // Si encontramos el correo asociado en la base de datos, iniciamos sesión con él
    if (emailEncontrado != null && emailEncontrado.isNotEmpty) {
      // ignore: avoid_print
      print('--> [AUTH] Autenticando en Supabase Auth con: $emailEncontrado');
      return await _supabase.auth.signInWithPassword(
        email: emailEncontrado,
        password: contrasena,
      );
    }

    // 3. Intentar con Phone nativo de Supabase Auth
    try {
      // ignore: avoid_print
      print('--> [AUTH] Probando Phone Auth nativo con: $telLimpio');
      return await _supabase.auth.signInWithPassword(
        phone: telLimpio,
        password: contrasena,
      );
    } catch (e) {
      // ignore: avoid_print
      print('--> [AUTH] Phone Auth nativo falló ($e). Probando identificador local...');
    }

    // 4. Intentar con email interno generado para el teléfono
    final emailGenerado = '$telLimpio@bygger.local';
    // ignore: avoid_print
    print('--> [AUTH] Probando email generado: $emailGenerado');
    return await _supabase.auth.signInWithPassword(
      email: emailGenerado,
      password: contrasena,
    );
  }

  // ============================================================
  // REGISTRAR USUARIO
  // ============================================================
  Future<AuthResponse> registrarUsuario({
    required String telefono,
    required String contrasena,
    required String nombre,
    required String apellido,
    String? correo,
  }) async {
    final telLimpio = telefono.trim();
    final emailFinal = (correo != null && correo.trim().isNotEmpty)
        ? correo.trim()
        : '$telLimpio@bygger.local';

    // Intentar registro con phone o con identificador único de teléfono
    try {
      final respuesta = await _supabase.auth.signUp(
        phone: telLimpio,
        password: contrasena,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telLimpio,
          'correo': emailFinal,
        },
      );

      if (respuesta.user != null) {
        return respuesta;
      }
    } catch (_) {
      // Si el proveedor de SMS no está activo en Supabase, registrar con el email interno asociado al teléfono
    }

    final respuesta = await _supabase.auth.signUp(
      email: emailFinal,
      password: contrasena,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telLimpio,
      },
    );

    if (respuesta.user == null) {
      throw Exception('No se pudo crear la cuenta');
    }

    return respuesta;
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  // ============================================================
  // OBTENER USUARIO ACTUAL
  // ============================================================
  User? get usuarioActual => _supabase.auth.currentUser;

  // ============================================================
  // OBTENER OBRAS DEL USUARIO
  // ============================================================
  Future<List<UsuarioObraModel>> obtenerObrasUsuario() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      print('NO HAY USUARIO AUTENTICADO');
      return [];
    }

    print('AUTH UID: ${usuario.id}');

    final usuarioBD = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuario.id)
        .maybeSingle();

    print('USUARIO BD: $usuarioBD');

    if (usuarioBD == null) {
      print('NO SE ENCONTRO EL USUARIO EN usuarios');
      return [];
    }

    final idUsuario = usuarioBD['id_usuario'] as int;

    print('ID USUARIO: $idUsuario');

    final respuesta = await _supabase
        .from('usuario_obra')
        .select('''
      id_usuario_obra,
      id_usuario,
      id_obra,
      id_rol,
      estado,
      obras(nombre),
      roles(nombre)
    ''')
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    print('RELACIONES usuario_obra: $respuesta');

    final relaciones = (respuesta as List)
        .map((item) => UsuarioObraModel.fromMap(item))
        .toList();

    print('RELACIONES CONVERTIDAS: ${relaciones.length}');

    return relaciones;
  }

  // ============================================================
  // OBTENER ID DEL USUARIO
  // ============================================================
  Future<int?> obtenerIdUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final respuesta = await Supabase.instance.client
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', user.id)
        .maybeSingle();

    if (respuesta == null) {
      return null;
    }

    return respuesta['id_usuario'] as int;
  }

  // ============================================================
  // ✅ NUEVO: VERIFICAR SI ES ADMINISTRADOR
  // ============================================================
  Future<bool> esAdministrador() async {
    final usuario = _supabase.auth.currentUser;
    
    if (usuario == null) {
      print('--> [ADMIN] No hay usuario autenticado');
      return false;
    }

    try {
      print('--> [ADMIN] Verificando si es admin para usuario: ${usuario.id}');

      // 1. Obtener ID del usuario en tabla 'usuarios'
      final usuarioBD = await _supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('id_auth', usuario.id)
          .maybeSingle();

      if (usuarioBD == null) {
        print('--> [ADMIN] Usuario no encontrado en tabla usuarios');
        return false;
      }

      final idUsuario = usuarioBD['id_usuario'] as int;
      print('--> [ADMIN] ID Usuario encontrado: $idUsuario');

      // 2. Buscar en 'usuario_obra' con JOIN a 'roles'
      final rol = await _supabase
          .from('usuario_obra')
          .select('''
            id_rol,
            roles (
              nombre
            )
          ''')
          .eq('id_usuario', idUsuario)
          .eq('estado', true)
          .maybeSingle();

      if (rol == null) {
        print('--> [ADMIN] No se encontró relación usuario_obra');
        return false;
      }

      // 3. Obtener el nombre del rol
      final rolData = rol['roles'] as Map?;
      final nombreRol = rolData != null 
          ? (rolData['nombre'] as String?)?.toLowerCase()
          : null;

      print('--> [ADMIN] Rol del usuario: $nombreRol');

      // 4. Verificar si es administrador
      final esAdmin = nombreRol == 'administrador' || nombreRol == 'admin';
      
      print('--> [ADMIN] ¿Es administrador? $esAdmin');
      return esAdmin;

    } catch (e) {
      print('--> [ADMIN] Error al verificar rol de administrador: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ NUEVO: OBTENER ROL DEL USUARIO
  // ============================================================
  Future<String?> obtenerRolUsuario() async {
    final usuario = _supabase.auth.currentUser;
    
    if (usuario == null) {
      return null;
    }

    try {
      final usuarioBD = await _supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('id_auth', usuario.id)
          .maybeSingle();

      if (usuarioBD == null) {
        return null;
      }

      final idUsuario = usuarioBD['id_usuario'] as int;

      final rol = await _supabase
          .from('usuario_obra')
          .select('''
            roles (
              nombre
            )
          ''')
          .eq('id_usuario', idUsuario)
          .eq('estado', true)
          .maybeSingle();

      if (rol != null && rol['roles'] != null) {
        final rolData = rol['roles'] as Map;
        return rolData['nombre'] as String?;
      }

      return null;
    } catch (e) {
      print('Error al obtener rol: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ NUEVO: OBTENER DATOS COMPLETOS DEL USUARIO
  // ============================================================
  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    final usuario = _supabase.auth.currentUser;
    
    if (usuario == null) {
      return null;
    }

    try {
      final usuarioBD = await _supabase
          .from('usuarios')
          .select('*')
          .eq('id_auth', usuario.id)
          .maybeSingle();

      if (usuarioBD == null) {
        return null;
      }

      final idUsuario = usuarioBD['id_usuario'] as int;

      final rol = await _supabase
          .from('usuario_obra')
          .select('''
            roles (
              nombre
            )
          ''')
          .eq('id_usuario', idUsuario)
          .eq('estado', true)
          .maybeSingle();

      String? nombreRol;
      if (rol != null && rol['roles'] != null) {
        final rolData = rol['roles'] as Map;
        nombreRol = rolData['nombre'] as String?;
      }

      return {
        'id': usuarioBD['id_usuario'],
        'nombre': usuarioBD['nombre'],
        'apellido': usuarioBD['apellido'],
        'telefono': usuarioBD['telefono'],
        'correo': usuarioBD['correo'],
        'rol': nombreRol,
        'esAdmin': nombreRol == 'administrador' || nombreRol == 'admin',
      };
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }
}