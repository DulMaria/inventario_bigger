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

    final idUsuario = usuario['id_usuario'] as int;

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
  // OBTENER OBRAS APROBADAS
  // ============================================================

  Future<List<ObraModel>> obtenerObrasAprobadas() async {
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
        .from('usuario_obra')
        .select('id_obra, obras(*)')
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    final obrasAprobadas = <ObraModel>[];

    for (final item in respuesta) {
      final obra = item['obras'];

      if (obra != null) {
        obrasAprobadas.add(ObraModel.fromMap(obra));
      }
    }

    return obrasAprobadas;
  }

  // ============================================================
  // OBTENER MIS OBRAS
  // ============================================================

  Future<List<ObraModel>> obtenerMisObras() async {
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

    final usuarioObras = await _supabase
        .from('usuario_obra')
        .select('id_obra')
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    if (usuarioObras.isEmpty) {
      return [];
    }

    final idsObras = (usuarioObras as List)
        .map((item) => item['id_obra'] as int)
        .toList();

    final obras = await _supabase
        .from('obras')
        .select()
        .inFilter('id_obra', idsObras)
        .eq('estado', true)
        .order('id_obra');

    return (obras as List).map((obra) => ObraModel.fromMap(obra)).toList();
  }

  // ============================================================
  // OBTENER ROL EN UNA OBRA
  // ============================================================

  Future<int?> obtenerRolEnObra(int idObra) async {
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
        .from('usuario_obra')
        .select('id_rol')
        .eq('id_usuario', idUsuario)
        .eq('id_obra', idObra)
        .eq('estado', true)
        .maybeSingle();

    if (respuesta == null) {
      return null;
    }

    return respuesta['id_rol'] as int;
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
  // SOLICITAR ACCESO
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

    final usuarioActual = await _supabase
        .from('usuarios')
        .select('id_usuario, nombre, apellido, correo')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuarioActual == null) {
      throw Exception('No se encontró el usuario actual en la base de datos');
    }

    final idUsuarioActual = usuarioActual['id_usuario'] as int;

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

    final respuesta = await _supabase
        .from('solicitudes_acceso')
        .select()
        .inFilter('id_obra', idsObrasGerente)
        .order('fecha', ascending: false);

    final solicitudes = List<Map<String, dynamic>>.from(respuesta);

    if (solicitudes.isEmpty) {
      return [];
    }

    final idsUsuarios = solicitudes
        .map((item) => item['id_usuario'] as int)
        .toSet()
        .toList();

    final idsObras = solicitudes
        .map((item) => item['id_obra'] as int)
        .toSet()
        .toList();

    final idsRoles = solicitudes
        .expand(
          (item) => [
            item['id_rol_solicitado'] as int,
            if (item['id_rol_aprobado'] != null) item['id_rol_aprobado'] as int,
          ],
        )
        .toSet()
        .toList();

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

    final obrasRespuesta = await _supabase
        .from('obras')
        .select('id_obra, nombre')
        .inFilter('id_obra', idsObras);

    final obras = <int, Map<String, dynamic>>{};

    for (final obra in obrasRespuesta) {
      obras[obra['id_obra'] as int] = Map<String, dynamic>.from(obra);
    }

    final rolesRespuesta = await _supabase
        .from('roles')
        .select('id_rol, nombre')
        .inFilter('id_rol', idsRoles);

    final roles = <int, Map<String, dynamic>>{};

    for (final rol in rolesRespuesta) {
      roles[rol['id_rol'] as int] = Map<String, dynamic>.from(rol);
    }

    for (final solicitud in solicitudes) {
      final idUsuario = solicitud['id_usuario'] as int;
      final idObra = solicitud['id_obra'] as int;
      final idRolSolicitado = solicitud['id_rol_solicitado'] as int;

      solicitud['usuario'] = usuarios[idUsuario];
      solicitud['obra'] = obras[idObra];
      solicitud['rol'] = roles[idRolSolicitado];

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
  // APROBAR CON OTRO ROL
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
