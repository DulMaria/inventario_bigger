import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/obra_model.dart';

class ObraService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ObraModel>> obtenerObras() async {
    final response = await _supabase
        .from('obras')
        .select()
        .order('id_obra');

    return response
        .map<ObraModel>((data) => ObraModel.fromMap(data))
        .toList();
  }

  Future<ObraModel> crearObra({
    required String nombre,
    String? direccion,
  }) async {
    final response = await _supabase
        .from('obras')
        .insert({
          'nombre': nombre,
          'direccion': direccion,
        })
        .select()
        .single();

    return ObraModel.fromMap(response);
  }
}