// lib/modules/solicitud_acceso/service/solicitud_acceso_service.dart
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

// lib/modules/solicitud_acceso/service/solicitud_acceso_service.dart

// ============================================================
// OBTENER SOLICITUDES - Gerente ve sus obras, Admin ve TODAS
// ============================================================

Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
  final usuarioAuth = _supabase.auth.currentUser;

  if (usuarioAuth == null) {
    print('❌ No hay usuario autenticado');
    throw Exception('No hay un usuario autenticado');
  }

  print('🔍 Usuario autenticado ID: ${usuarioAuth.id}');

  final usuarioActual = await _supabase
      .from('usuarios')
      .select('id_usuario, nombre, apellido, correo')
      .eq('id_auth', usuarioAuth.id)
      .maybeSingle();

  if (usuarioActual == null) {
    print('❌ Usuario no encontrado en tabla usuarios');
    throw Exception('No se encontró el usuario en la base de datos');
  }

  final idUsuarioActual = usuarioActual['id_usuario'] as int;
  print('🔍 ID Usuario en tabla usuarios: $idUsuarioActual');

  // ✅ OBTENER EL ROL DEL USUARIO ACTUAL
  final rolesUsuario = await _supabase
      .from('usuario_obra')
      .select('id_rol, id_obra')
      .eq('id_usuario', idUsuarioActual)
      .eq('estado', true);

  print('🔍 Roles del usuario: ${rolesUsuario.length}');

  if (rolesUsuario.isEmpty) {
    print('❌ Usuario sin roles asignados');
    return [];
  }

  // Obtener todos los roles del usuario
  final List<int> rolesIds = rolesUsuario.map((r) => r['id_rol'] as int).toList();
  print('🔍 IDs de roles: $rolesIds');

  // ✅ SI ES ADMINISTRADOR (id_rol = 8) → VER TODAS LAS SOLICITUDES
  if (rolesIds.contains(8)) {
    print('📋 [ADMIN] Usuario es Administrador - Obteniendo TODAS las solicitudes...');
    
    final solicitudes = await _supabase
        .from('solicitudes_acceso')
        .select('''
          *,
          usuarios!inner (
            id_usuario,
            nombre,
            apellido,
            telefono,
            correo
          ),
          obras!inner (
            id_obra,
            nombre,
            direccion
          )
        ''')
        .order('fecha', ascending: false);

    print('📋 [ADMIN] Solicitudes encontradas: ${solicitudes.length}');

    List<Map<String, dynamic>> solicitudesConDetalles = [];

    for (var solicitud in solicitudes) {
      final idRolSolicitado = solicitud['id_rol_solicitado'] as int?;

      Map<String, dynamic> solicitudDetalle = Map<String, dynamic>.from(solicitud);

      if (idRolSolicitado != null) {
        final rolSolicitado = await _supabase
            .from('roles')
            .select('nombre')
            .eq('id_rol', idRolSolicitado)
            .maybeSingle();
        solicitudDetalle['rol_solicitado'] = rolSolicitado?['nombre'] ?? 'Sin rol';
      } else {
        solicitudDetalle['rol_solicitado'] = 'Sin rol';
      }

      if (solicitud['id_rol_aprobado'] != null) {
        final idRolAprobado = solicitud['id_rol_aprobado'] as int;
        final rolAprobado = await _supabase
            .from('roles')
            .select('nombre')
            .eq('id_rol', idRolAprobado)
            .maybeSingle();
        solicitudDetalle['rol_aprobado'] = rolAprobado?['nombre'] ?? 'Sin rol';
      }

      solicitudesConDetalles.add(solicitudDetalle);
    }

    return solicitudesConDetalles;
  }

  // ✅ SI ES GERENTE (id_rol = 3) → VER SOLO SUS OBRAS
  if (rolesIds.contains(3)) {
    print('📋 [GERENTE] Usuario es Gerente - Obteniendo solicitudes de sus obras...');

    // Obtener obras donde es gerente
    final obrasGerente = await _supabase
        .from('usuario_obra')
        .select('id_obra')
        .eq('id_usuario', idUsuarioActual)
        .eq('id_rol', 3)
        .eq('estado', true);

    final idsObrasGerente = (obrasGerente as List)
        .map((item) => item['id_obra'] as int)
        .toList();

    print('📋 [GERENTE] IDs de obras: $idsObrasGerente');

    if (idsObrasGerente.isEmpty) {
      print('📋 [GERENTE] No es gerente en ninguna obra');
      return [];
    }

    final respuesta = await _supabase
        .from('solicitudes_acceso')
        .select('''
          *,
          usuarios!inner (
            id_usuario,
            nombre,
            apellido,
            telefono,
            correo
          ),
          obras!inner (
            id_obra,
            nombre,
            direccion
          )
        ''')
        .inFilter('id_obra', idsObrasGerente)
        .order('fecha', ascending: false);

    print('📋 [GERENTE] Solicitudes encontradas: ${respuesta.length}');

    List<Map<String, dynamic>> solicitudesConDetalles = [];

    for (var solicitud in respuesta) {
      final idRolSolicitado = solicitud['id_rol_solicitado'] as int?;

      Map<String, dynamic> solicitudDetalle = Map<String, dynamic>.from(solicitud);

      if (idRolSolicitado != null) {
        final rolSolicitado = await _supabase
            .from('roles')
            .select('nombre')
            .eq('id_rol', idRolSolicitado)
            .maybeSingle();
        solicitudDetalle['rol_solicitado'] = rolSolicitado?['nombre'] ?? 'Sin rol';
      } else {
        solicitudDetalle['rol_solicitado'] = 'Sin rol';
      }

      if (solicitud['id_rol_aprobado'] != null) {
        final idRolAprobado = solicitud['id_rol_aprobado'] as int;
        final rolAprobado = await _supabase
            .from('roles')
            .select('nombre')
            .eq('id_rol', idRolAprobado)
            .maybeSingle();
        solicitudDetalle['rol_aprobado'] = rolAprobado?['nombre'] ?? 'Sin rol';
      }

      solicitudesConDetalles.add(solicitudDetalle);
    }

    return solicitudesConDetalles;
  }

  // ✅ OTROS ROLES → NO VEN SOLICITUDES
  print('📋 [OTRO ROL] Usuario con roles $rolesIds no tiene permisos para ver solicitudes');
  return [];
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

  // ============================================================
  // ✅ NUEVO: OBTENER TODAS LAS SOLICITUDES (PARA ADMIN)
  // ✅ ESTE MÉTODO DEBE ESTAR DENTRO DE LA CLASE
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerTodasLasSolicitudes() async {
    try {
      print('📋 [ADMIN] Obteniendo TODAS las solicitudes...');

      final solicitudes = await _supabase
          .from('solicitudes_acceso')
          .select('''
            *,
            usuarios!inner (
              id_usuario,
              nombre,
              apellido,
              telefono,
              correo
            ),
            obras!inner (
              id_obra,
              nombre,
              direccion
            )
          ''')
          .order('fecha', ascending: false);

      print('📋 [ADMIN] Solicitudes encontradas: ${solicitudes.length}');

      List<Map<String, dynamic>> solicitudesConDetalles = [];

      for (var solicitud in solicitudes) {
        final idRolSolicitado = solicitud['id_rol_solicitado'] as int?;

        Map<String, dynamic> solicitudDetalle = Map<String, dynamic>.from(solicitud);

        // Obtener nombre del rol solicitado
        if (idRolSolicitado != null) {
          final rolSolicitado = await _supabase
              .from('roles')
              .select('nombre')
              .eq('id_rol', idRolSolicitado)
              .maybeSingle();
          solicitudDetalle['rol_solicitado'] = rolSolicitado?['nombre'] ?? 'Sin rol';
        } else {
          solicitudDetalle['rol_solicitado'] = 'Sin rol';
        }

        // Si tiene rol aprobado
        if (solicitud['id_rol_aprobado'] != null) {
          final idRolAprobado = solicitud['id_rol_aprobado'] as int;
          final rolAprobado = await _supabase
              .from('roles')
              .select('nombre')
              .eq('id_rol', idRolAprobado)
              .maybeSingle();
          solicitudDetalle['rol_aprobado'] = rolAprobado?['nombre'] ?? 'Sin rol';
        }

        solicitudesConDetalles.add(solicitudDetalle);
      }

      return solicitudesConDetalles;
    } catch (e) {
      print('❌ Error al obtener todas las solicitudes: $e');
      return [];
    }
  }
}