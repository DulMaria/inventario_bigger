import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/obra_model.dart';
import '../../../models/solicitud_acceso_model.dart';

class SolicitudAccesoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // OBTENER OBRAS DISPONIBLES
  // ============================================================

  Future<List<ObraModel>> obtenerObrasDisponibles() async {
    final usuarioAuth = _supabase.auth.currentUser;

    if (usuarioAuth == null) {
      throw Exception('No hay un usuario autenticado');
    }

    final usuario = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuario == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    final idUsuario = usuario['id_usuario'];

    final obras = await _supabase
        .from('obras')
        .select()
        .eq('estado', true)
        .order('id_obra');

    final obrasUsuario = await _supabase
        .from('usuario_obra')
        .select('id_obra')
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    final idsObrasUsuario = (obrasUsuario as List)
        .map((item) => item['id_obra'] as int)
        .toSet();

    final solicitudesPendientes = await _supabase
        .from('solicitudes_acceso')
        .select('id_obra')
        .eq('id_usuario', idUsuario)
        .eq('estado', 'PENDIENTE');

    final idsObrasPendientes = (solicitudesPendientes as List)
        .map((item) => item['id_obra'] as int)
        .toSet();

    final obrasDisponibles = (obras as List)
        .where((obra) {
          final idObra = obra['id_obra'] as int;

          return !idsObrasUsuario.contains(idObra) &&
              !idsObrasPendientes.contains(idObra);
        })
        .map((obra) => ObraModel.fromMap(obra))
        .toList();

    return obrasDisponibles;
  }

  // ============================================================
  // OBTENER ROLES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerRoles() async {
    final respuesta = await _supabase
        .from('roles')
        .select('id_rol, nombre')
        .order('id_rol');

    return List<Map<String, dynamic>>.from(respuesta);
  }

  // ============================================================
  // ENVIAR SOLICITUD DE ACCESO
  // ============================================================

  Future<SolicitudAccesoModel> solicitarAcceso({
    required int idObra,
    required int idRolSolicitado,
  }) async {
    final usuarioAuth = _supabase.auth.currentUser;

    if (usuarioAuth == null) {
      throw Exception('No hay un usuario autenticado');
    }

    final usuario = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuario == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    final idUsuario = usuario['id_usuario'] as int;

    final pertenece = await _supabase
        .from('usuario_obra')
        .select('id_usuario_obra')
        .eq('id_usuario', idUsuario)
        .eq('id_obra', idObra)
        .eq('estado', true)
        .maybeSingle();

    if (pertenece != null) {
      throw Exception('Ya tienes acceso a esta obra');
    }

    final solicitudExistente = await _supabase
        .from('solicitudes_acceso')
        .select('id_solicitud_acceso')
        .eq('id_usuario', idUsuario)
        .eq('id_obra', idObra)
        .eq('estado', 'PENDIENTE')
        .maybeSingle();

    if (solicitudExistente != null) {
      throw Exception('Ya tienes una solicitud pendiente para esta obra');
    }

    final respuesta = await _supabase
        .from('solicitudes_acceso')
        .insert({
          'id_usuario': idUsuario,
          'id_obra': idObra,
          'id_rol_solicitado': idRolSolicitado,
          'estado': 'PENDIENTE',
        })
        .select()
        .single();

    return SolicitudAccesoModel.fromMap(respuesta);
  }

  // ============================================================
  // OBTENER MIS SOLICITUDES
  // ============================================================

  Future<List<SolicitudAccesoModel>> obtenerMisSolicitudes() async {
    final usuarioAuth = _supabase.auth.currentUser;

    if (usuarioAuth == null) {
      throw Exception('No hay un usuario autenticado');
    }

    final usuario = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuario == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    final idUsuario = usuario['id_usuario'] as int;

    final respuesta = await _supabase
        .from('solicitudes_acceso')
        .select()
        .eq('id_usuario', idUsuario)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((item) => SolicitudAccesoModel.fromMap(item))
        .toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES PARA EL GERENTE
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    final usuarioAuth = _supabase.auth.currentUser;

    if (usuarioAuth == null) {
      throw Exception('No hay un usuario autenticado');
    }

    // Buscar al usuario autenticado
    final usuarioActual = await _supabase
        .from('usuarios')
        .select('id_usuario, nombre, apellido, correo')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuarioActual == null) {
      throw Exception('No se encontró el usuario actual en la base de datos');
    }

    final idUsuarioActual = usuarioActual['id_usuario'] as int;

    // Obtener las obras donde este usuario es gerente
    final obrasGerente = await _supabase
        .from('usuario_obra')
        .select('id_obra')
        .eq('id_usuario', idUsuarioActual)
        .eq('id_rol', 3)
        .eq('estado', true);

    final idsObrasGerente = (obrasGerente as List)
        .map((item) => item['id_obra'] as int)
        .toList();

    if (idsObrasGerente.isEmpty) {
      return [];
    }

    // Obtener solicitudes
    final respuesta = await _supabase
        .from('solicitudes_acceso')
        .select()
        .inFilter('id_obra', idsObrasGerente)
        .order('fecha', ascending: false);

    final solicitudes = List<Map<String, dynamic>>.from(respuesta);

    if (solicitudes.isEmpty) {
      return [];
    }

    // Obtener IDs de usuarios
    final idsUsuarios = solicitudes
        .map((item) => item['id_usuario'] as int)
        .toSet()
        .toList();

    // Obtener IDs de obras
    final idsObras = solicitudes
        .map((item) => item['id_obra'] as int)
        .toSet()
        .toList();

    // Obtener IDs de roles solicitados Y aprobados
    final idsRoles = solicitudes
        .expand(
          (item) => [
            item['id_rol_solicitado'] as int,
            if (item['id_rol_aprobado'] != null) item['id_rol_aprobado'] as int,
          ],
        )
        .toSet()
        .toList();

    // Obtener usuarios
    final usuariosRespuesta = await _supabase
        .from('usuarios')
        .select('id_usuario, nombre, apellido, correo')
        .inFilter('id_usuario', idsUsuarios);

    final usuarios = <int, Map<String, dynamic>>{};

    for (final usuario in usuariosRespuesta) {
      usuarios[usuario['id_usuario'] as int] = Map<String, dynamic>.from(
        usuario,
      );
    }

    // Obtener obras
    final obrasRespuesta = await _supabase
        .from('obras')
        .select('id_obra, nombre')
        .inFilter('id_obra', idsObras);

    final obras = <int, Map<String, dynamic>>{};

    for (final obra in obrasRespuesta) {
      obras[obra['id_obra'] as int] = Map<String, dynamic>.from(obra);
    }

    // Obtener roles
    final rolesRespuesta = await _supabase
        .from('roles')
        .select('id_rol, nombre')
        .inFilter('id_rol', idsRoles);

    final roles = <int, Map<String, dynamic>>{};

    for (final rol in rolesRespuesta) {
      roles[rol['id_rol'] as int] = Map<String, dynamic>.from(rol);
    }

    // Unir toda la información
    for (final solicitud in solicitudes) {
      final idUsuario = solicitud['id_usuario'] as int;
      final idObra = solicitud['id_obra'] as int;
      final idRolSolicitado = solicitud['id_rol_solicitado'] as int;

      solicitud['usuario'] = usuarios[idUsuario];
      solicitud['obra'] = obras[idObra];
      solicitud['rol'] = roles[idRolSolicitado];

      // Agregar información del rol aprobado
      if (solicitud['id_rol_aprobado'] != null) {
        final idRolAprobado = solicitud['id_rol_aprobado'] as int;

        solicitud['rol_aprobado'] = roles[idRolAprobado];
      }
    }

    return solicitudes;
  }

  // ============================================================
  // APROBAR SOLICITUD
  // ============================================================

  Future<void> aprobarSolicitud({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    // Primero agregamos al usuario a la obra
    await _supabase.from('usuario_obra').insert({
      'id_usuario': idUsuario,
      'id_obra': idObra,
      'id_rol': idRol,
      'estado': true,
    });

    // Después actualizamos la solicitud
    await _supabase
        .from('solicitudes_acceso')
        .update({'estado': 'APROBADA', 'id_rol_aprobado': idRol})
        .eq('id_solicitud_acceso', idSolicitud);
  }

  // ============================================================
  // RECHAZAR SOLICITUD
  // ============================================================

  Future<void> rechazarSolicitud({
    required int idSolicitud,
    String? observacion,
  }) async {
    await _supabase
        .from('solicitudes_acceso')
        .update({'estado': 'RECHAZADA', 'observacion': observacion})
        .eq('id_solicitud_acceso', idSolicitud);
  }

  // ============================================================
  // CAMBIAR ROL Y APROBAR
  // ============================================================

  Future<void> aprobarConRol({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    await _supabase.from('usuario_obra').insert({
      'id_usuario': idUsuario,
      'id_obra': idObra,
      'id_rol': idRol,
      'estado': true,
    });

    await _supabase
        .from('solicitudes_acceso')
        .update({'estado': 'APROBADA', 'id_rol_aprobado': idRol})
        .eq('id_solicitud_acceso', idSolicitud);
  }
}
