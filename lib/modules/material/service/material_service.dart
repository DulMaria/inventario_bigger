import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/material_model.dart';

class MaterialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // NORMALIZACIÓN DE TEXTO (Quita acentos, tildes y mayúsculas)
  // ============================================================

  static String normalizar(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  Future<List<MaterialModel>> obtenerMateriales() async {
    final respuesta = await _supabase
        .from('materiales')
        .select()
        .order('nombre');

    return (respuesta as List)
        .map((material) => MaterialModel.fromMap(material))
        .toList();
  }

  // ============================================================
  // BÚSQUEDA PREDICTIVA / SUGERENCIAS MIENTRAS ESCRIBE
  // ============================================================

  Future<List<MaterialModel>> buscarSugerencias(String query) async {
    final queryNorm = normalizar(query);
    if (queryNorm.isEmpty) return [];

    final todos = await obtenerMateriales();

    return todos.where((m) {
      final nombreNorm = normalizar(m.nombre);
      final codigoNorm = (m.codigo ?? '').toLowerCase();
      return nombreNorm.contains(queryNorm) || codigoNorm.contains(queryNorm);
    }).toList();
  }

  // ============================================================
  // BUSCAR MATERIAL (Insensible a acentos, mayúsculas y espacios)
  // ============================================================

  Future<MaterialModel?> buscarMaterial(String nombre) async {
    final nombreNorm = normalizar(nombre);
    if (nombreNorm.isEmpty) return null;

    final todos = await obtenerMateriales();

    for (final m in todos) {
      if (normalizar(m.nombre) == nombreNorm) {
        return m;
      }
    }

    return null;
  }

  // ============================================================
  // CREAR MATERIAL (Evita duplicados por acentos)
  // ============================================================

  Future<MaterialModel> crearMaterial({required String nombre}) async {
    final nombreLimpio = nombre.trim();

    // 1. Verificamos si ya existe con o sin acento (ej. Hormigón == Hormigon)
    final existente = await buscarMaterial(nombreLimpio);

    if (existente != null) {
      return existente;
    }

    // 2. Obtenemos el siguiente correlativo numérico.
    int numero = await _obtenerSiguienteNumero();

    // 3. Generamos las iniciales del material.
    final iniciales = _obtenerIniciales(nombreLimpio);

    // 4. Asegurar código único
    String codigo = 'I$iniciales${numero.toString().padLeft(3, '0')}';

    final existenteConMismoCodigo = await _supabase
        .from('materiales')
        .select('id_material')
        .eq('codigo', codigo)
        .maybeSingle();

    if (existenteConMismoCodigo != null) {
      numero++;
      codigo = 'I$iniciales${numero.toString().padLeft(3, '0')}';
    }

    try {
      final respuesta = await _supabase
          .from('materiales')
          .insert({'codigo': codigo, 'nombre': nombreLimpio})
          .select()
          .single();

      return MaterialModel.fromMap(respuesta);
    } catch (_) {
      // Si por concurrencia falló el código, reintentar con número incrementado
      numero += 2;
      codigo = 'I$iniciales${numero.toString().padLeft(3, '0')}';
      final respuesta = await _supabase
          .from('materiales')
          .insert({'codigo': codigo, 'nombre': nombreLimpio})
          .select()
          .single();

      return MaterialModel.fromMap(respuesta);
    }
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
