import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/piso_model.dart';

class PisoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Crear piso
  Future<PisoModel> crearPiso({
    required int idObra,
    required String nombre,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .insert({
          'id_obra': idObra,
          'nombre': nombre,
          'estado_obra': 'NO INICIADO',
        })
        .select('*, obras(*)')
        .single();

    return PisoModel.fromMap(respuesta);
  }

  // Obtener pisos de una obra
  Future<List<PisoModel>> obtenerPisos(int idObra) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('*, obras(*)')
        .eq('id_obra', idObra)
        .order('id_piso');

    return (respuesta as List)
        .map((piso) => PisoModel.fromMap(piso))
        .toList();
  }

  // Editar piso
  Future<PisoModel> editarPiso({
    required int idPiso,
    required String nombre,
    required String estadoObra,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .update({
          'nombre': nombre,
          'estado_obra': estadoObra,
        })
        .eq('id_piso', idPiso)
        .select()
        .single();

    return PisoModel.fromMap(respuesta);
  }
}