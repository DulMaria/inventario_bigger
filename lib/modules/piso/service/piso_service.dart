import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/piso_model.dart';

class PisoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CREAR PISO
  // ============================================================

  Future<PisoModel> crearPiso({
    required int idObra,
    required String nombre,
    required String tipoPiso,
    required int numeroPiso,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .insert({
          'id_obra': idObra,
          'nombre': nombre,
          'estado_obra': 'NO INICIADO',
          'tipo_piso': tipoPiso,
          'numero_piso': numeroPiso,
          'estado': true,
        })
        .select('*, obras(*)')
        .single();

    return PisoModel.fromMap(respuesta);
  }

  // ============================================================
  // OBTENER PISOS
  // ============================================================

  Future<List<PisoModel>> obtenerPisos(int idObra) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('*, obras(*)')
        .eq('id_obra', idObra)
        .order('numero_piso', ascending: false);

    return (respuesta as List).map((piso) => PisoModel.fromMap(piso)).toList();
  }

  // ============================================================
  // EDITAR PISO
  // ============================================================

  Future<PisoModel> editarPiso({
    required int idPiso,
    required String nombre,
    required String estadoObra,
    required String tipoPiso,
    required int numeroPiso,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .update({
          'nombre': nombre,
          'estado_obra': estadoObra,
          'tipo_piso': tipoPiso,
          'numero_piso': numeroPiso,
        })
        .eq('id_piso', idPiso)
        .select('*, obras(*)')
        .single();

    return PisoModel.fromMap(respuesta);
  }

  // ============================================================
  // NOMBRE DUPLICADO AL CREAR
  // ============================================================

  Future<bool> existePisoConNombre({
    required int idObra,
    required String nombre,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('id_piso')
        .eq('id_obra', idObra)
        .eq('estado', true)
        .ilike('nombre', nombre.trim());

    return (respuesta as List).isNotEmpty;
  }

  // ============================================================
  // NOMBRE DUPLICADO AL EDITAR
  // ============================================================

  Future<bool> existeOtroPisoConNombre({
    required int idObra,
    required int idPisoActual,
    required String nombre,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('id_piso')
        .eq('id_obra', idObra)
        .eq('estado', true)
        .ilike('nombre', nombre.trim())
        .neq('id_piso', idPisoActual);

    return (respuesta as List).isNotEmpty;
  }

  // ============================================================
  // NÚMERO DUPLICADO AL CREAR
  // ============================================================

  Future<bool> existeNumeroPiso({
    required int idObra,
    required int numeroPiso,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('id_piso')
        .eq('id_obra', idObra)
        .eq('numero_piso', numeroPiso)
        .eq('estado', true);

    return (respuesta as List).isNotEmpty;
  }

  // ============================================================
  // NÚMERO DUPLICADO AL EDITAR
  // ============================================================

  Future<bool> existeOtroNumeroPiso({
    required int idObra,
    required int idPisoActual,
    required int numeroPiso,
  }) async {
    final respuesta = await _supabase
        .from('pisos')
        .select('id_piso')
        .eq('id_obra', idObra)
        .eq('numero_piso', numeroPiso)
        .eq('estado', true)
        .neq('id_piso', idPisoActual);

    return (respuesta as List).isNotEmpty;
  }
}
