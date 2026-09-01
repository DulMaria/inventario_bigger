import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/solicitud_obrero_model.dart';

class SolicitudObreroService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CREAR SOLICITUD DE OBRERO
  // ============================================================

  Future<void> crearSolicitudObrero({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('La solicitud debe contener al menos un material.');
    }

    // ------------------------------------------------------------
    // 1. CREAR SOLICITUD DEL OBRERO
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // 2. CREAR DETALLES
    // ------------------------------------------------------------

    final detalles = materiales.map((m) {
      return {
        'id_solicitud_obrero': idSolicitudObrero,
        'id_material': m['id_material'],
        'cantidad': m['cantidad'],
      };
    }).toList();

    try {
      await _supabase.from('detalle_solicitud_obrero').insert(detalles);
    } catch (e) {
      // Si falla la creación de los detalles,
      // eliminamos la solicitud creada para no dejar
      // una solicitud vacía.
      await _supabase
          .from('solicitudes_obrero')
          .delete()
          .eq('id_solicitud_obrero', idSolicitudObrero);

      rethrow;
    }
  }

  // ============================================================
  // OBTENER SOLICITUDES DEL OBRERO POR PISO
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPorPiso({
    required int idPiso,
    required int idUsuario,
  }) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select('''
          *,
          pisos(*),
          usuarios(*),
          detalle_solicitud_obrero(
            *,
            materiales(*)
          )
          ''')
        .eq('id_piso', idPiso)
        .eq('id_usuario', idUsuario)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s as Map<String, dynamic>))
        .toList();
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
        .select('''
          *,
          pisos!inner(*),
          usuarios(*),
          detalle_solicitud_obrero(
            *,
            materiales(*)
          )
          ''')
        .eq('id_usuario', idUsuario)
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES PENDIENTES PARA EL TÉCNICO
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPendientesPorObra(
    int idObra,
  ) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select('''
          *,
          pisos!inner(*),
          usuarios(*),
          detalle_solicitud_obrero(
            *,
            materiales(*)
          )
          ''')
        .eq('pisos.id_obra', idObra)
        .inFilter('estado', ['PENDIENTE', 'PENDIENTE_REVISION'])
        .order('fecha', ascending: true);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // HISTORIAL DE SOLICITUDES DE OBREROS
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerTodasPorObra(int idObra) async {
    final respuesta = await _supabase
        .from('solicitudes_obrero')
        .select('''
          *,
          pisos!inner(*),
          usuarios(*),
          detalle_solicitud_obrero(
            *,
            materiales(*)
          )
          ''')
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudObreroModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // TÉCNICO: APROBAR SOLICITUD
  // Crear solicitud oficial para Compras
  // ============================================================

  Future<void> aprobarYSometerACompras({
    required int idSolicitudObrero,
    required int idPiso,
    required int idTecnicoUsuario,
    required List<Map<String, dynamic>> materiales,
    String? observacion,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('No se puede aprobar una solicitud sin materiales.');
    }

    // ------------------------------------------------------------
    // 1. CREAR SOLICITUD OFICIAL
    // ------------------------------------------------------------

    final solicitudOficial = await _supabase
        .from('solicitudes')
        .insert({
          'id_piso': idPiso,
          'id_usuario': idTecnicoUsuario,
          'estado': 'PENDIENTE',
          'observacion': observacion ?? 'Solicitud aprobada por técnico',
        })
        .select()
        .single();

    final idSolicitudOficial = solicitudOficial['id_solicitud'] as int;

    // ------------------------------------------------------------
    // 2. CREAR DETALLES OFICIALES
    // ------------------------------------------------------------

    final detallesOficiales = materiales.map((m) {
      return {
        'id_solicitud': idSolicitudOficial,
        'id_material': m['id_material'],
        'cantidad': m['cantidad'],
      };
    }).toList();

    try {
      await _supabase.from('detalle_solicitud').insert(detallesOficiales);

      // ----------------------------------------------------------
      // 3. ACTUALIZAR DETALLES DEL OBRERO CON LO CORREGIDO
      // ----------------------------------------------------------

      try {
        await _supabase
            .from('detalle_solicitud_obrero')
            .delete()
            .eq('id_solicitud_obrero', idSolicitudObrero);

        final nuevosDetallesObrero = materiales.map((m) {
          return {
            'id_solicitud_obrero': idSolicitudObrero,
            'id_material': m['id_material'],
            'cantidad': m['cantidad'],
          };
        }).toList();

        await _supabase
            .from('detalle_solicitud_obrero')
            .insert(nuevosDetallesObrero);
      } catch (_) {}

      // ----------------------------------------------------------
      // 4. ACTUALIZAR SOLICITUD DEL OBRERO
      // ----------------------------------------------------------

      await _supabase
          .from('solicitudes_obrero')
          .update({
            'estado': 'APROBADA',
            'id_solicitud_creada': idSolicitudOficial,
            'observacion': observacion,
          })
          .eq('id_solicitud_obrero', idSolicitudObrero);
    } catch (e) {
      // Si algo falla después de crear la solicitud oficial,
      // intentamos eliminarla para evitar datos incompletos.
      await _supabase
          .from('solicitudes')
          .delete()
          .eq('id_solicitud', idSolicitudOficial);

      rethrow;
    }
  }

  // ============================================================
  // TÉCNICO: RECHAZAR SOLICITUD
  // ============================================================

  Future<void> rechazarSolicitudObrero({
    required int idSolicitudObrero,
    required String observacion,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('Debes indicar el motivo del rechazo.');
    }

    await _supabase
        .from('solicitudes_obrero')
        .update({'estado': 'RECHAZADA', 'observacion': observacion.trim()})
        .eq('id_solicitud_obrero', idSolicitudObrero);
  }
}
