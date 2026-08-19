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

    // Buscar el usuario en nuestra tabla usuarios
    final usuario = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuario == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    final idUsuario = usuario['id_usuario'];

    // Obtener todas las obras
    final obras = await _supabase
        .from('obras')
        .select()
        .eq('estado', true)
        .order('id_obra');

    // Obtener obras a las que ya pertenece el usuario
    final obrasUsuario = await _supabase
        .from('usuario_obra')
        .select('id_obra')
        .eq('id_usuario', idUsuario)
        .eq('estado', true);

    final idsObrasUsuario = (obrasUsuario as List)
        .map((item) => item['id_obra'] as int)
        .toSet();

    // Obtener solicitudes pendientes
    final solicitudesPendientes = await _supabase
        .from('solicitudes_acceso')
        .select('id_obra')
        .eq('id_usuario', idUsuario)
        .eq('estado', 'PENDIENTE');

    final idsObrasPendientes = (solicitudesPendientes as List)
        .map((item) => item['id_obra'] as int)
        .toSet();

    // Filtrar obras:
    // - No pertenece actualmente
    // - No tiene una solicitud pendiente
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

    // Buscar usuario
    final usuario = await _supabase
        .from('usuarios')
        .select('id_usuario')
        .eq('id_auth', usuarioAuth.id)
        .maybeSingle();

    if (usuario == null) {
      throw Exception('No se encontró el usuario en la base de datos');
    }

    final idUsuario = usuario['id_usuario'] as int;

    // Comprobar si ya pertenece a la obra
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

    // Comprobar si ya tiene una solicitud pendiente
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

    // Crear solicitud
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
  // OBTENER SOLICITUDES DEL USUARIO
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
}
