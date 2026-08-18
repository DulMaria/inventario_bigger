import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/obra_model.dart';

class ObraService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CREAR OBRA
  // ============================================================

  Future<ObraModel> crearObra({
    required String nombre,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    final respuesta = await _supabase
        .from('obras')
        .insert({
          'nombre': nombre,
          'direccion': direccion,
          'latitud': latitud,
          'longitud': longitud,
          'estado': true,
        })
        .select()
        .single();

    return ObraModel.fromMap(respuesta);
  }

  // ============================================================
  // OBTENER OBRAS
  // ============================================================

  Future<List<ObraModel>> obtenerObras() async {
    final respuesta = await _supabase.from('obras').select().order('id_obra');

    return (respuesta as List).map((obra) => ObraModel.fromMap(obra)).toList();
  }

  // ============================================================
  // EDITAR OBRA
  // ============================================================

  Future<ObraModel> editarObra({
    required int idObra,
    required String nombre,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    final respuesta = await _supabase
        .from('obras')
        .update({
          'nombre': nombre,
          'direccion': direccion,
          'latitud': latitud,
          'longitud': longitud,
        })
        .eq('id_obra', idObra)
        .select()
        .single();

    return ObraModel.fromMap(respuesta);
  }

  // ============================================================
  // COMPROBAR SI EXISTE UNA OBRA CON EL NOMBRE
  // ============================================================

  Future<bool> existeObraConNombre(String nombre) async {
    final respuesta = await _supabase
        .from('obras')
        .select('id_obra')
        .ilike('nombre', nombre.trim());

    return (respuesta as List).isNotEmpty;
  }

  // ============================================================
  // COMPROBAR SI EXISTE OTRA OBRA CON EL MISMO NOMBRE
  // ============================================================

  Future<bool> existeOtraObraConNombre(String nombre, int idObraActual) async {
    final respuesta = await _supabase
        .from('obras')
        .select('id_obra')
        .ilike('nombre', nombre.trim())
        .neq('id_obra', idObraActual);

    return (respuesta as List).isNotEmpty;
  }
}
