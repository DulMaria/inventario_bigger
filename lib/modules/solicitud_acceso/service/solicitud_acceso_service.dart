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
        .order('id_usuario_obra', ascending: false)
        .limit(1);

    if ((respuesta as List).isEmpty) {
      return null;
    }

    final rolRaw = respuesta.first['id_rol'];
    if (rolRaw is int) return rolRaw;
    if (rolRaw is String) return int.tryParse(rolRaw);
    return null;
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
  // OBTENER SOLICITUDES (100% Robusto, sin depender de joins frágiles)
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerSolicitudes({int? idObraFiltro}) async {
    dynamic respuesta;

    // 1. Si se especificó una obra puntual (ej. Gerente entrando a su obra)
    if (idObraFiltro != null) {
      respuesta = await _supabase
          .from('solicitudes_acceso')
          .select()
          .eq('id_obra', idObraFiltro)
          .order('fecha', ascending: false);
    } else {
      // 2. Si no se especificó obra (Vista Global de Administrador)
      respuesta = await _supabase
          .from('solicitudes_acceso')
          .select()
          .order('fecha', ascending: false);
    }

    final listaSolicitudes = List<Map<String, dynamic>>.from(respuesta as List);

    if (listaSolicitudes.isEmpty) {
      return [];
    }

    // 3. Traer usuarios, obras y roles para mapear detalles sin riesgo de error de schema
    return await _completarDetallesRoles(listaSolicitudes);
  }

  Future<List<Map<String, dynamic>>> _completarDetallesRoles(
    List<Map<String, dynamic>> solicitudes,
  ) async {
    // Mapa de Roles
    final Map<int, String> rolesMap = {};
    try {
      final roles = await _supabase.from('roles').select('id_rol, nombre');
      for (var r in roles) {
        if (r['id_rol'] != null) {
          rolesMap[r['id_rol'] as int] = r['nombre'].toString();
        }
      }
    } catch (_) {}

    // Mapa de Obras
    final Map<int, Map<String, dynamic>> obrasMap = {};
    try {
      final obras = await _supabase.from('obras').select('id_obra, nombre, direccion');
      for (var o in obras) {
        if (o['id_obra'] != null) {
          obrasMap[o['id_obra'] as int] = Map<String, dynamic>.from(o);
        }
      }
    } catch (_) {}

    // Mapa de Usuarios
    final Map<int, Map<String, dynamic>> usuariosMap = {};
    try {
      final usuarios = await _supabase
          .from('usuarios')
          .select('id_usuario, nombre, apellido, telefono, correo');
      for (var u in usuarios) {
        if (u['id_usuario'] != null) {
          usuariosMap[u['id_usuario'] as int] = Map<String, dynamic>.from(u);
        }
      }
    } catch (_) {}

    List<Map<String, dynamic>> resultado = [];

    for (var solicitud in solicitudes) {
      Map<String, dynamic> item = Map<String, dynamic>.from(solicitud);

      final idUser = item['id_usuario'] as int?;
      final idObra = item['id_obra'] as int?;
      final idRolSol = item['id_rol_solicitado'] as int?;
      final idRolApr = item['id_rol_aprobado'] as int?;

      item['usuarios'] = idUser != null ? usuariosMap[idUser] : null;
      item['obras'] = idObra != null ? obrasMap[idObra] : null;
      item['rol_solicitado'] = idRolSol != null
          ? (rolesMap[idRolSol] ?? 'Rol #$idRolSol')
          : 'Sin rol';
      item['rol_aprobado'] = idRolApr != null
          ? (rolesMap[idRolApr] ?? 'Rol #$idRolApr')
          : 'No especificado';

      resultado.add(item);
    }

    return resultado;
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
    // 1. Desactivar asignaciones previas en esta obra para evitar duplicados
    try {
      await _supabase
          .from('usuario_obra')
          .update({'estado': false})
          .eq('id_usuario', idUsuario)
          .eq('id_obra', idObra);
    } catch (_) {}

    // 2. Insertar el nuevo rol activo
    await _supabase.from('usuario_obra').insert({
      'id_usuario': idUsuario,
      'id_obra': idObra,
      'id_rol': idRol,
      'estado': true,
    });

    // 3. Actualizar el estado de la solicitud
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
  // APROBAR CON OTRO ROL (ADMIN)
  // ============================================================
  Future<void> aprobarConRol({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    // 1. Desactivar asignaciones previas en esta obra
    try {
      await _supabase
          .from('usuario_obra')
          .update({'estado': false})
          .eq('id_usuario', idUsuario)
          .eq('id_obra', idObra);
    } catch (_) {}

    // 2. Insertar con el rol especificado por el Administrador
    await _supabase.from('usuario_obra').insert({
      'id_usuario': idUsuario,
      'id_obra': idObra,
      'id_rol': idRol,
      'estado': true,
    });

    // 3. Actualizar solicitud
    await _supabase
        .from('solicitudes_acceso')
        .update({'estado': 'APROBADA', 'id_rol_aprobado': idRol})
        .eq('id_solicitud_acceso', idSolicitud);
  }

  // ============================================================
  // OBTENER TODAS LAS SOLICITUDES (PARA ADMIN)
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerTodasLasSolicitudes() async {
    return await obtenerSolicitudes(idObraFiltro: null);
  }
}