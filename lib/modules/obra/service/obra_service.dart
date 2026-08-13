import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/obra_model.dart';

class ObraService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ObraModel> crearObra({
    required String nombre,
    String? direccion,
  }) async {
    final respuesta = await _supabase
        .from('obras')
        .insert({
          'nombre': nombre,
          'direccion': direccion,
          'estado': true,
        })
        .select()
        .single();

    return ObraModel.fromMap(respuesta);
  }

  Future<List<ObraModel>> obtenerObras() async {
    final respuesta = await _supabase
        .from('obras')
        .select()
        .order('id_obra');

    return (respuesta as List)
        .map((obra) => ObraModel.fromMap(obra))
        .toList();
  }

  Future<ObraModel> editarObra({
    required int idObra,
    required String nombre,
    String? direccion,
  }) async {
    final respuesta = await _supabase
        .from('obras')
        .update({
          'nombre': nombre,
          'direccion': direccion,
        })
        .eq('id_obra', idObra)
        .select()
        .single();

    return ObraModel.fromMap(respuesta);
  }
}