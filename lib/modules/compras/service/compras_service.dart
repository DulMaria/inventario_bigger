// lib/modules/compras/service/compras_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';

class ComprasService {
  final SupabaseClient _supabase = Supabase.instance.client;


  // ============================================================
  // OBTENER SOLICITUDES ENVIADAS A GERENTE (En espera de decisión)
  // ============================================================
  Future<List<SolicitudModel>> obtenerSolicitudesEnviadasAGerente(int idObra) async {
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
        .eq('estado', 'PENDIENTE')
        .order('fecha', ascending: false);

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    // Filtramos aquellas que ya tienen ruta_imagen cargada o nota de revisión
    return lista.where((s) {
      final tieneFoto = s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty);
      final tieneNota = s.observacion != null && s.observacion!.contains('[COTIZACIONES_ENVIADAS]');
      return tieneFoto || tieneNota;
    }).toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES PENDIENTES DE COTIZAR (Para Compras)
  // ============================================================
  Future<List<SolicitudModel>> obtenerSolicitudesACotizar(int idObra) async {
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
        .eq('estado', 'PENDIENTE')
        .order('fecha', ascending: false);

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    // Filtramos aquellas que NO tienen cotizaciones subidas todavía
    return lista.where((s) {
      final tieneFoto = s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty);
      final tieneNota = s.observacion != null && s.observacion!.contains('[COTIZACIONES_ENVIADAS]');
      return !tieneFoto && !tieneNota;
    }).toList();
  }

  // ============================================================
  // OBTENER SOLICITUDES APROBADAS (Listas para compra)
  // ============================================================
  Future<List<SolicitudModel>> obtenerSolicitudesAprobadas(int idObra) async {
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
        .eq('estado', 'APROBADA')
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // OBTENER TODAS LAS SOLICITUDES PARA EL ADMINISTRADOR
  // ============================================================
  Future<List<SolicitudModel>> obtenerTodasLasSolicitudesAdmin({
    int? idObraFiltro,
  }) async {
    dynamic query = _supabase.from('solicitudes').select('''
          *,
          pisos!inner(
            *,
            obras(*)
          ),
          usuarios(*),
          detalle_solicitud(
            *,
            materiales(*)
          )
        ''');

    if (idObraFiltro != null) {
      query = query.eq('pisos.id_obra', idObraFiltro);
    }

    final respuesta = await query.order('fecha', ascending: false);

    return (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // OBTENER COTIZACIONES DE UNA SOLICITUD
  // ============================================================
  Future<List<CotizacionModel>> obtenerCotizacionesPorSolicitud(int idSolicitud) async {
    try {
      final respuesta = await _supabase
          .from('cotizaciones')
          .select()
          .eq('id_solicitud', idSolicitud)
          .order('precio_total', ascending: true);

      return (respuesta as List)
          .map((c) => CotizacionModel.fromMap(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Si la tabla cotizaciones aún no existe, retornamos lista vacía
      return [];
    }
  }

  // ============================================================
  // SUBIR FOTO DE PROFORMA (A Storage o Base64 Data URI)
  // ============================================================
  Future<String?> subirImagenProforma({
    required File archivo,
    required int idSolicitud,
    required int indiceCotizacion,
  }) async {
    try {
      final ext = archivo.path.split('.').last.toLowerCase();
      final fileName = 'solicitud_${idSolicitud}_cotiz_${indiceCotizacion}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      try {
        final bytes = await archivo.readAsBytes();
        await _supabase.storage.from('proformas').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );

        final url = _supabase.storage.from('proformas').getPublicUrl(fileName);
        return url;
      } catch (storageError) {
        // Fallback: Convertir a base64 Data URI si el bucket no está creado en Supabase
        final bytes = await archivo.readAsBytes();
        final base64Str = base64Encode(bytes);
        return 'data:image/$ext;base64,$base64Str';
      }
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // GUARDAR COTIZACIONES Y ENVIAR AL GERENTE
  // ============================================================
  Future<void> guardarCotizacionesYEnviarAGerente({
    required int idSolicitud,
    required int idUsuarioCompras,
    required List<CotizacionModel> cotizaciones,
    String? imagenPrincipalProforma,
  }) async {
    if (cotizaciones.isEmpty) {
      throw Exception('Debes registrar al menos una cotización.');
    }

    // 1. Guardar en la tabla cotizaciones (únicamente fotos de proformas)
    try {
      for (final cot in cotizaciones) {
        await _supabase.from('cotizaciones').insert({
          'id_solicitud': idSolicitud,
          'id_usuario': idUsuarioCompras,
          'imagen_url': cot.imagenUrl,
          'estado': 'PENDIENTE',
        });
      }
    } catch (e) {
      // ignore
    }

    // 2. Guardar la imagen en detalle_solicitud si aplica
    if (imagenPrincipalProforma != null && imagenPrincipalProforma.isNotEmpty) {
      try {
        await _supabase
            .from('detalle_solicitud')
            .update({'ruta_imagen': imagenPrincipalProforma})
            .eq('id_solicitud', idSolicitud);
      } catch (_) {}
    } else if (cotizaciones.isNotEmpty && cotizaciones.first.imagenUrl != null) {
      try {
        await _supabase
            .from('detalle_solicitud')
            .update({'ruta_imagen': cotizaciones.first.imagenUrl})
            .eq('id_solicitud', idSolicitud);
      } catch (_) {}
    }

    // 3. Actualizar observacion de la solicitud manteniendo estado PENDIENTE
    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'PENDIENTE',
          'observacion': '[COTIZACIONES_ENVIADAS] Cotizaciones recibidas y enviadas a revisión del Gerente',
        })
        .eq('id_solicitud', idSolicitud);
  }

  // ============================================================
  // GERENTE / ADMIN: AUTORIZAR Y SELECCIONAR COTIZACIÓN
  // ============================================================
  Future<void> autorizarCotizacion({
    required int idSolicitud,
    required int idCotizacion,
    required int idUsuarioGerente,
    String? observacionGerente,
  }) async {
    // 1. Marcar la cotización seleccionada como 'SELECCIONADA' y las demás como 'RECHAZADA'
    try {
      await _supabase
          .from('cotizaciones')
          .update({'estado': 'RECHAZADA'})
          .eq('id_solicitud', idSolicitud);

      await _supabase
          .from('cotizaciones')
          .update({'estado': 'SELECCIONADA'})
          .eq('id_cotizacion', idCotizacion);
    } catch (_) {}

    // 2. Actualizar estado de la solicitud a 'APROBADA'
    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'APROBADA',
          'observacion': observacionGerente ?? 'Cotización autorizada por Gerente',
        })
        .eq('id_solicitud', idSolicitud);

    // 3. Registrar en aprobaciones
    try {
      await _supabase.from('aprobaciones').insert({
        'id_solicitud': idSolicitud,
        'id_usuario': idUsuarioGerente,
        'estado': 'APROBADA',
        'comentario': observacionGerente ?? 'Proforma autorizada para compra',
      });
    } catch (_) {}
  }

  // ============================================================
  // COMPRAS: MARCAR COMO COMPRADO
  // ============================================================
  Future<void> marcarComoComprado({
    required int idSolicitud,
    String? observacion,
  }) async {
    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'COMPRADO',
          'observacion': observacion ?? 'Materiales adquiridos por Compras',
        })
        .eq('id_solicitud', idSolicitud);
  }
}
