import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/material_model.dart';

class MaterialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MaterialModel>> obtenerMateriales() async {
    final respuesta = await _supabase
        .from('materiales')
        .select()
        .order('nombre');

    return (respuesta as List)
        .map((material) => MaterialModel.fromMap(material))
        .toList();
  }

  Future<MaterialModel?> buscarMaterial(String nombre) async {
    final nombreLimpio = nombre.trim();

    final respuesta = await _supabase
        .from('materiales')
        .select()
        .ilike('nombre', nombreLimpio)
        .maybeSingle();

    if (respuesta == null) {
      return null;
    }

    return MaterialModel.fromMap(respuesta);
  }

  Future<MaterialModel> crearMaterial({required String nombre}) async {
    final nombreLimpio = nombre.trim();

    // Primero verificamos si ya existe.
    final existente = await buscarMaterial(nombreLimpio);

    if (existente != null) {
      return existente;
    }

    // Obtenemos el siguiente número de la secuencia.
    final numero = await _obtenerSiguienteNumero();

    // Generamos las iniciales del material.
    final iniciales = _obtenerIniciales(nombreLimpio);

    // Ejemplo: ICL001
    final codigo = 'I$iniciales${numero.toString().padLeft(3, '0')}';

    final respuesta = await _supabase
        .from('materiales')
        .insert({'codigo': codigo, 'nombre': nombreLimpio})
        .select()
        .single();

    return MaterialModel.fromMap(respuesta);
  }

  Future<int> _obtenerSiguienteNumero() async {
    final materiales = await _supabase.from('materiales').select('codigo');

    int mayor = 0;

    for (final material in materiales) {
      final codigo = material['codigo'];

      if (codigo == null) {
        continue;
      }

      final texto = codigo.toString();

      if (texto.length < 4) {
        continue;
      }

      final numeroTexto = texto.substring(texto.length - 3);
      final numero = int.tryParse(numeroTexto);

      if (numero != null && numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }

  String _obtenerIniciales(String nombre) {
    final palabras = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.isNotEmpty)
        .toList();

    if (palabras.length == 1) {
      final palabra = palabras.first.toUpperCase();

      if (palabra.length >= 2) {
        return palabra.substring(0, 2);
      }

      return palabra.padRight(2, 'X');
    }

    final iniciales = palabras
        .take(2)
        .map((palabra) => palabra[0].toUpperCase())
        .join();

    return iniciales.padRight(2, 'X');
  }
}
