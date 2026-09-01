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
      final obras = await _supabase.from('obras').select();
      final totalObras = obras.length;

      final usuarios = await _supabase.from('usuarios').select();
      final totalUsuarios = usuarios.length;

      final materiales = await _supabase.from('materiales').select();
      final totalMateriales = materiales.length;

      final solicitudesPendientes = await _supabase
          .from('solicitudes_acceso')
          .select()
          .eq('estado', 'PENDIENTE');
      final totalSolicitudesPendientes = solicitudesPendientes.length;

      final solicitudesRecientes = await _supabase
          .from('solicitudes_acceso')
          .select('''
            *,
            usuarios!inner (
              nombre,
              apellido,
              telefono
            ),
            obras!inner (
              nombre,
              direccion
            )
          ''')
          .order('fecha', ascending: false)
          .limit(5);

      return {
        'total_obras': totalObras,
        'total_usuarios': totalUsuarios,
        'total_materiales': totalMateriales,
        'solicitudes_pendientes': totalSolicitudesPendientes,
        'solicitudes_recientes': solicitudesRecientes as List<Map<String, dynamic>>,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
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

      List<Map<String, dynamic>> usuariosConRol = [];

      for (var usuario in usuarios) {
        final idUsuario = usuario['id_usuario'] as int;

        final relaciones = await _supabase
            .from('usuario_obra')
            .select('''
              id_rol,
              id_obra,
              roles!inner (
                nombre
              ),
              obras!inner (
                nombre
              )
            ''')
            .eq('id_usuario', idUsuario)
            .eq('estado', true);

        String? rol;
        List<String> obras = [];

        for (var rel in relaciones) {
          if (rel['roles'] != null) {
            final rolData = rel['roles'] as Map<String, dynamic>;
            final rolNombre = rolData['nombre'] as String?;
            if (rol == null && rolNombre != null) {
              rol = rolNombre;
            }
          }

          if (rel['obras'] != null) {
            final obraData = rel['obras'] as Map<String, dynamic>;
            final obraNombre = obraData['nombre'] as String?;
            if (obraNombre != null) {
              obras.add(obraNombre);
            }
          }
        }

        usuariosConRol.add({
          ...usuario,
          'rol': rol ?? 'Sin rol',
          'obras': obras,
        });
      }

      return usuariosConRol;
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
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