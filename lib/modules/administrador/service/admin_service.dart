import 'package:inventario_bigger/core/config/app_colors.dart';
// lib/modules/administrador/service/admin_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../solicitud_acceso/service/solicitud_acceso_service.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SolicitudAccesoService _solicitudService = SolicitudAccesoService();

  // ============================================================
  // DASHBOARD - Estadísticas
  // ============================================================
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final obras = await _supabase.from('obras').select('id_obra');
      final totalObras = (obras as List).length;

      final usuarios = await _supabase.from('usuarios').select('id_usuario');
      final totalUsuarios = (usuarios as List).length;

      final materiales = await _supabase.from('materiales').select('id_material');
      final totalMateriales = (materiales as List).length;

      final solicitudes = await _solicitudService.obtenerTodasLasSolicitudes();
      final totalSolicitudesPendientes = solicitudes
          .where((s) => (s['estado'] ?? 'PENDIENTE') == 'PENDIENTE')
          .length;

      final solicitudesRecientes = solicitudes.take(5).toList();

      return {
        'total_obras': totalObras,
        'total_usuarios': totalUsuarios,
        'total_materiales': totalMateriales,
        'solicitudes_pendientes': totalSolicitudesPendientes,
        'solicitudes_recientes': solicitudesRecientes,
      };
    } catch (e) {
      return {
        'total_obras': 0,
        'total_usuarios': 0,
        'total_materiales': 0,
        'solicitudes_pendientes': 0,
        'solicitudes_recientes': <Map<String, dynamic>>[],
      };
    }
  }

  // ============================================================
  // OBRAS
  // ============================================================
  Future<List<Map<String, dynamic>>> getObras() async {
    try {
      final obras = await _supabase
          .from('obras')
          .select()
          .eq('estado', true)
          .order('nombre');

      return List<Map<String, dynamic>>.from(obras);
    } catch (e) {
      print('Error al obtener obras: $e');
      return [];
    }
  }

  // ============================================================
  // USUARIOS
  // ============================================================
  Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final usuarios = await _supabase
          .from('usuarios')
          .select('*')
          .order('nombre', ascending: true);

      // 1. Mapa de Roles
      final Map<int, String> rolesMap = {};
      try {
        final roles = await _supabase.from('roles').select('id_rol, nombre');
        for (var r in (roles as List)) {
          if (r['id_rol'] != null) {
            final id = (r['id_rol'] as num).toInt();
            rolesMap[id] = r['nombre']?.toString() ?? 'Rol #$id';
          }
        }
      } catch (_) {}

      // 2. Mapa de Obras
      final Map<int, String> obrasMap = {};
      try {
        final obras = await _supabase.from('obras').select('id_obra, nombre');
        for (var o in (obras as List)) {
          if (o['id_obra'] != null) {
            final id = (o['id_obra'] as num).toInt();
            obrasMap[id] = o['nombre']?.toString() ?? 'Obra #$id';
          }
        }
      } catch (_) {}

      // 3. Mapeo de usuario_obra por id_usuario
      final Map<int, List<Map<String, dynamic>>> usuarioObrasMap = {};
      try {
        final uoRes = await _supabase.from('usuario_obra').select('*');
        for (var item in (uoRes as List)) {
          final uMap = Map<String, dynamic>.from(item);
          final idUser = uMap['id_usuario'] != null ? (uMap['id_usuario'] as num).toInt() : null;
          if (idUser != null) {
            usuarioObrasMap.putIfAbsent(idUser, () => []).add(uMap);
          }
        }
      } catch (_) {}

      // 4. Mapeo de solicitudes_acceso APROBADAS como respaldo por id_usuario
      final Map<int, List<Map<String, dynamic>>> solAprobadasMap = {};
      try {
        final solRes = await _supabase
            .from('solicitudes_acceso')
            .select('*')
            .eq('estado', 'APROBADA');
        for (var item in (solRes as List)) {
          final sMap = Map<String, dynamic>.from(item);
          final idUser = sMap['id_usuario'] != null ? (sMap['id_usuario'] as num).toInt() : null;
          if (idUser != null) {
            solAprobadasMap.putIfAbsent(idUser, () => []).add(sMap);
          }
        }
      } catch (_) {}

      List<Map<String, dynamic>> usuariosConRol = [];

      for (var u in (usuarios as List)) {
        final usuario = Map<String, dynamic>.from(u);
        final idUsuario = (usuario['id_usuario'] as num).toInt();

        final relaciones = usuarioObrasMap[idUsuario] ?? [];
        final solAprobadas = solAprobadasMap[idUsuario] ?? [];

        String? rolPrincipal;
        List<String> obrasList = [];
        List<Map<String, dynamic>> obrasDetalladas = [];
        final Set<int> obrasProcesadas = {};

        // A. Procesar registros de usuario_obra
        for (var rel in relaciones) {
          final idRol = rel['id_rol'] != null ? (rel['id_rol'] as num).toInt() : null;
          final nombreRol = idRol != null ? (rolesMap[idRol] ?? 'Sin rol') : 'Sin rol';

          if (idRol != null && rolPrincipal == null) {
            rolPrincipal = nombreRol;
          }

          final idObra = rel['id_obra'] != null ? (rel['id_obra'] as num).toInt() : null;
          final nombreObra = idObra != null ? (obrasMap[idObra] ?? 'Obra #$idObra') : 'Obra Desconocida';
          final estadoRel = rel['estado'] == true;

          if (idObra != null) {
            obrasProcesadas.add(idObra);
            if (estadoRel) {
              obrasList.add(nombreObra);
            }

            obrasDetalladas.add({
              'id_obra': idObra,
              'nombre_obra': nombreObra,
              'id_rol': idRol,
              'nombre_rol': nombreRol,
              'estado': estadoRel,
            });
          }
        }

        // B. Procesar respaldo de solicitudes_acceso APROBADAS
        for (var sol in solAprobadas) {
          final idObra = sol['id_obra'] != null ? (sol['id_obra'] as num).toInt() : null;
          if (idObra != null && !obrasProcesadas.contains(idObra)) {
            final idRol = sol['id_rol_aprobado'] != null
                ? (sol['id_rol_aprobado'] as num).toInt()
                : (sol['id_rol_solicitado'] != null ? (sol['id_rol_solicitado'] as num).toInt() : null);

            final nombreRol = idRol != null ? (rolesMap[idRol] ?? 'Sin rol') : 'Sin rol';
            final nombreObra = obrasMap[idObra] ?? 'Obra #$idObra';

            if (idRol != null && rolPrincipal == null) {
              rolPrincipal = nombreRol;
            }

            obrasProcesadas.add(idObra);
            obrasList.add(nombreObra);

            obrasDetalladas.add({
              'id_obra': idObra,
              'nombre_obra': nombreObra,
              'id_rol': idRol,
              'nombre_rol': nombreRol,
              'estado': true,
            });
          }
        }

        usuariosConRol.add({
          ...usuario,
          'rol': rolPrincipal ?? 'Sin rol',
          'obras': obrasList,
          'obras_detalladas': obrasDetalladas,
          'estado': usuario['estado'] ?? true,
        });
      }

      return usuariosConRol;
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // CAMBIAR ESTADO DE USUARIO EN UNA OBRA ESPECÍFICA
  // ============================================================
  Future<void> cambiarEstadoUsuarioObra({
    required int idUsuario,
    required int idObra,
    required bool estado,
  }) async {
    await _supabase
        .from('usuario_obra')
        .update({'estado': estado})
        .eq('id_usuario', idUsuario)
        .eq('id_obra', idObra);
  }

  // ============================================================
  // CAMBIAR ESTADO DE USUARIO A NIVEL GLOBAL
  // ============================================================
  Future<void> cambiarEstadoUsuarioGlobal({
    required int idUsuario,
    required bool estado,
  }) async {
    await _supabase
        .from('usuarios')
        .update({'estado': estado})
        .eq('id_usuario', idUsuario);
  }

  // ============================================================
  // ROLES
  // ============================================================
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final roles = await _supabase
          .from('roles')
          .select('*')
          .order('id_rol', ascending: true);

      return List<Map<String, dynamic>>.from(roles);
    } catch (e) {
      print('Error al obtener roles: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ SOLICITUDES - Obtener TODAS las solicitudes (ADMIN)
  // ============================================================
  Future<List<Map<String, dynamic>>> getSolicitudes() async {
    try {
      print('📋 [ADMIN] Obteniendo todas las solicitudes...');
      
      final solicitudes = await _solicitudService.obtenerTodasLasSolicitudes();
      
      print('✅ [ADMIN] Solicitudes cargadas: ${solicitudes.length}');
      return solicitudes;
    } catch (e) {
      print('❌ Error al obtener solicitudes: $e');
      return [];
    }
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
    await _solicitudService.aprobarSolicitud(
      idSolicitud: idSolicitud,
      idUsuario: idUsuario,
      idObra: idObra,
      idRol: idRol,
    );
  }

  // ============================================================
  // RECHAZAR SOLICITUD
  // ============================================================
  Future<void> rechazarSolicitud({
    required int idSolicitud,
    String? observacion,
  }) async {
    await _solicitudService.rechazarSolicitud(
      idSolicitud: idSolicitud,
      observacion: observacion,
    );
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
    await _solicitudService.aprobarConRol(
      idSolicitud: idSolicitud,
      idUsuario: idUsuario,
      idObra: idObra,
      idRol: idRol,
    );
  }

  // ============================================================
  // DASHBOARD - Obtener datos del administrador
  // ============================================================
  Future<Map<String, dynamic>?> getAdminData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final usuario = await _supabase
          .from('usuarios')
          .select('*')
          .eq('id_auth', user.id)
          .maybeSingle();

      if (usuario == null) return null;

      return Map<String, dynamic>.from(usuario);
    } catch (e) {
      print('Error al obtener admin data: $e');
      return null;
    }
  }
}