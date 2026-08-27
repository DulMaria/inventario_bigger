import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> crearSolicitud({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
  }) async {
    final solicitud = await _supabase
        .from('solicitudes')
        .insert({
          'id_piso': idPiso,
          'id_usuario': idUsuario,
          'estado': 'PENDIENTE',
        })
        .select()
        .single();

    final idSolicitud = solicitud['id_solicitud'];

    final detalles = materiales.map((material) {
      return {
        'id_solicitud': idSolicitud,
        'id_material': material['id_material'],
        'cantidad': material['cantidad'],
      };
    }).toList();

    await _supabase.from('detalle_solicitud').insert(detalles);
  }
}
