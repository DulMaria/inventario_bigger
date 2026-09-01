import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/solicitud_model.dart';

class SolicitudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CREAR SOLICITUD DIRECTA A COMPRAS
  // ============================================================

  Future<void> crearSolicitud({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
    String? observacion,
  }) async {
    final solicitud = await _supabase
        .from('solicitudes')
        .insert({
          'id_piso': idPiso,
          'id_usuario': idUsuario,
          'estado': 'PENDIENTE',
          'observacion': observacion,
        })
        .select()
        .single();

    final idSolicitud = solicitud['id_solicitud'] as int;

    final detalles = materiales.map((material) {
      return {
        'id_solicitud': idSolicitud,
        'id_material': material['id_material'],
        'cantidad': material['cantidad'],
      };
    }).toList();

    await _supabase.from('detalle_solicitud').insert(detalles);
  }

  // ============================================================
  // OBTENER SOLICITUDES POR PISO (Para mostrar en MaterialesView)
  // ============================================================

  Future<List<SolicitudModel>> obtenerSolicitudesPorPiso({
    required int idPiso,
    required int idUsuario,
  }) async {
    final respuesta = await _supabase
        .from('solicitudes')
        .select('''
          *,
          pisos(*),
          usuarios(*),
          detalle_solicitud(
            *,
            materiales(*)
          )
        ''')
        .eq('id_piso', idPiso)
        .eq('id_usuario', idUsuario)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES DEL USUARIO EN LA OBRA
  // ============================================================

  Future<List<SolicitudModel>> obtenerSolicitudesPorUsuario({
    required int idUsuario,
    required int idObra,
  }) async {
    final respuesta = await _supabase
        .from('solicitudes')
        .select('''
          *,
          pisos!inner(*),
          usuarios(*),
          detalle_solicitud(
            *,
            materiales(*)
          )
        ''')
        .eq('id_usuario', idUsuario)
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // OBTENER TODAS LAS SOLICITUDES DE LA OBRA (A Compras)
  // ============================================================

  Future<List<SolicitudModel>> obtenerTodasPorObra(int idObra) async {
    final respuesta = await _supabase
        .from('solicitudes')
        .select('''
          *,
          pisos!inner(*),
          usuarios(*),
          detalle_solicitud(
            *,
            materiales(*)
          )
        ''')
        .eq('pisos.id_obra', idObra)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }
}
