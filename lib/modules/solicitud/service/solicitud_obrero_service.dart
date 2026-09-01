import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/solicitud_obrero_model.dart';

class SolicitudObreroService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CREAR SOLICITUD DE OBRERO (Revisión por Técnico)
  // ============================================================

  Future<void> crearSolicitudObrero({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
  }) async {
    final solicitud = await _supabase
        .from('solicitudes_obrero')
        .insert({
          'id_piso': idPiso,
          'id_usuario': idUsuario,
          'estado': 'PENDIENTE_REVISION',
        })
        .select()
        .single();

    final idSolicitudObrero = solicitud['id_solicitud_obrero'] as int;

    final detalles = materiales.map((m) {
      return {
        'id_solicitud_obrero': idSolicitudObrero,
        'id_material': m['id_material'],
        'cantidad': m['cantidad'],
      };
    }).toList();

    await _supabase.from('detalle_solicitud_obrero').insert(detalles);
  }

  // ============================================================
  // OBTENER SOLICITUDES DEL OBRERO POR OBRA
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPorUsuario({
    required int idUsuario,
    required int idObra,
  }) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select(
          '*, pisos!inner(*), usuarios(*), detalle_solicitud_obrero(*, materiales(*))',
        )
        .eq('id_usuario', idUsuario)
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s))
        .toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES PENDIENTES PARA EL TÉCNICO EN LA OBRA
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPendientesPorObra(
    int idObra,
  ) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select(
          '*, pisos!inner(*), usuarios(*), detalle_solicitud_obrero(*, materiales(*))',
        )
        .eq('pisos.id_obra', idObra)
        .eq('estado', 'PENDIENTE_REVISION')
        .order('fecha', ascending: true);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s))
        .toList();
  }

  // ============================================================
  // OBTENER HISTORIAL DE TODAS LAS SOLICITUDES DE OBREROS EN LA OBRA
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerTodasPorObra(int idObra) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select(
          '*, pisos!inner(*), usuarios(*), detalle_solicitud_obrero(*, materiales(*))',
        )
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s))
        .toList();
  }

  // ============================================================
  // TÉCNICO: APROBAR SOLICITUD DE OBRERO (Crear solicitud oficial para compras)
  // ============================================================

  Future<void> aprobarYSometerACompras({
    required int idSolicitudObrero,
    required int idPiso,
    required int idTecnicoUsuario,
    required List<Map<String, dynamic>> materiales,
    String? observacion,
  }) async {
    // 1. Crear solicitud oficial en `solicitudes`
    final solicitudOficial = await _supabase
        .from('solicitudes')
        .insert({
          'id_piso': idPiso,
          'id_usuario': idTecnicoUsuario,
          'estado': 'PENDIENTE',
          'observacion': observacion ?? 'Aprobado por técnico',
        })
        .select()
        .single();

    final idSolicitudOficial = solicitudOficial['id_solicitud'] as int;

    // 2. Insertar detalles oficiales en `detalle_solicitud`
    final detallesOficiales = materiales.map((m) {
      return {
        'id_solicitud': idSolicitudOficial,
        'id_material': m['id_material'],
        'cantidad': m['cantidad'],
      };
    }).toList();

    await _supabase.from('detalle_solicitud').insert(detallesOficiales);

    // 3. Actualizar la solicitud del obrero a APROBADA y vincular la solicitud oficial
    await _supabase
        .from('solicitudes_obrero')
        .update({
          'estado': 'APROBADA',
          'id_solicitud_creada': idSolicitudOficial,
          'observacion': observacion,
        })
        .eq('id_solicitud_obrero', idSolicitudObrero);
  }

  // ============================================================
  // TÉCNICO: RECHAZAR SOLICITUD DE OBRERO
  // ============================================================

  Future<void> rechazarSolicitudObrero({
    required int idSolicitudObrero,
    required String observacion,
  }) async {
    await _supabase
        .from('solicitudes_obrero')
        .update({
          'estado': 'RECHAZADA',
          'observacion': observacion,
        })
        .eq('id_solicitud_obrero', idSolicitudObrero);
  }
}
