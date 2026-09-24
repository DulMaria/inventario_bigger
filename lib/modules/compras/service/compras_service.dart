import 'package:inventario_bigger/core/config/app_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../../../models/material_model.dart';
import '../../../models/detalle_solicitud_model.dart';

class ComprasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ENRIQUECER MATERIALES DE SOLICITUDES Y RECUPERAR DETALLES
  // ============================================================
  Future<List<SolicitudModel>> _enriquecerMateriales(List<SolicitudModel> lista) async {
    if (lista.isEmpty) return lista;

    Map<int, MaterialModel> mapaMateriales = {};
    try {
      final resMat = await _supabase.from('materiales').select();
      final listaMat = (resMat as List)
          .map((m) => MaterialModel.fromMap(m as Map<String, dynamic>))
          .toList();
      for (final m in listaMat) {
        mapaMateriales[m.idMaterial] = m;
      }
    } catch (_) {}

    final listaEnriquecida = <SolicitudModel>[];
    for (final sol in lista) {
      var detallesActuales = sol.detalles;

      // Fallback de rescate: Si detalles vino vacío por RLS en join anidado, consultar detalle_solicitud directamente
      if (detallesActuales.isEmpty) {
        try {
          final resDet = await _supabase
              .from('detalle_solicitud')
              .select('*, materiales(*)')
              .eq('id_solicitud', sol.idSolicitud);

          if ((resDet as List).isNotEmpty) {
            detallesActuales = (resDet as List)
                .map((d) => DetalleSolicitudModel.fromMap(Map<String, dynamic>.from(d)))
                .toList();
          }
        } catch (_) {}
      }

      final nuevosDetalles = <DetalleSolicitudModel>[];
      for (final det in detallesActuales) {
        final idMat = det.material?.idMaterial ?? det.idMaterial;
        final realMat = (idMat != null && mapaMateriales.containsKey(idMat))
            ? mapaMateriales[idMat]
            : det.material;

        nuevosDetalles.add(DetalleSolicitudModel(
          idDetalle: det.idDetalle,
          solicitud: det.solicitud,
          material: realMat ?? det.material,
          cantidad: det.cantidad,
          rutaImagen: det.rutaImagen,
          idMaterial: idMat,
        ));
      }

      listaEnriquecida.add(SolicitudModel(
        idSolicitud: sol.idSolicitud,
        piso: sol.piso,
        usuario: sol.usuario,
        fecha: sol.fecha,
        estado: sol.estado,
        observacion: sol.observacion,
        detalles: nuevosDetalles,
      ));
    }

    return listaEnriquecida;
  }

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

    final listaEnviadas = <SolicitudModel>[];

    for (final s in lista) {
      final tieneFotoDetalles = s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty);
      final tieneNotaObs = s.observacion != null &&
          (s.observacion!.contains('[COTIZACIONES_ENVIADAS]') || s.observacion!.contains('[PROFORMAS:'));

      bool tieneCotizDb = false;
      if (!tieneFotoDetalles && !tieneNotaObs) {
        try {
          final resCotiz = await _supabase
              .from('cotizaciones')
              .select('id_cotizacion')
              .eq('id_solicitud', s.idSolicitud)
              .limit(1);
          tieneCotizDb = (resCotiz as List).isNotEmpty;
        } catch (_) {}
      }

      if (tieneFotoDetalles || tieneNotaObs || tieneCotizDb) {
        listaEnviadas.add(s);
      }
    }

    return await _enriquecerMateriales(listaEnviadas);
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

    final listaACotizar = <SolicitudModel>[];

    for (final s in lista) {
      final tieneFotoDetalles = s.detalles.any((d) => d.rutaImagen != null && d.rutaImagen!.isNotEmpty);
      final tieneNotaObs = s.observacion != null &&
          (s.observacion!.contains('[COTIZACIONES_ENVIADAS]') || s.observacion!.contains('[PROFORMAS:'));

      bool tieneCotizDb = false;
      if (!tieneFotoDetalles && !tieneNotaObs) {
        try {
          final resCotiz = await _supabase
              .from('cotizaciones')
              .select('id_cotizacion')
              .eq('id_solicitud', s.idSolicitud)
              .limit(1);
          tieneCotizDb = (resCotiz as List).isNotEmpty;
        } catch (_) {}
      }

      if (!tieneFotoDetalles && !tieneNotaObs && !tieneCotizDb) {
        listaACotizar.add(s);
      }
    }

    return await _enriquecerMateriales(listaACotizar);
  }

  // ============================================================
  // OBTENER UNA SOLICITUD POR SU ID
  // ============================================================
  Future<SolicitudModel?> obtenerSolicitudPorId(int idSolicitud) async {
    try {
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
          .eq('id_solicitud', idSolicitud)
          .maybeSingle();

      if (respuesta != null) {
        final sol = SolicitudModel.fromMap(Map<String, dynamic>.from(respuesta));
        final listaEnriquecida = await _enriquecerMateriales([sol]);
        return listaEnriquecida.isNotEmpty ? listaEnriquecida.first : sol;
      }
    } catch (_) {}
    return null;
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

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    return await _enriquecerMateriales(lista);
  }

  // ============================================================
  // OBTENER SOLICITUDES COMPRADAS / HISTORIAL
  // ============================================================
  Future<List<SolicitudModel>> obtenerSolicitudesCompradas(int idObra) async {
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
        .eq('estado', 'COMPRADO')
        .order('fecha', ascending: false);

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    return await _enriquecerMateriales(lista);
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

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    return await _enriquecerMateriales(lista);
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
      // Si la tabla cotizaciones aún no existe o hay error, retornamos lista vacía
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

    final urlsFotos = cotizaciones.map((c) => c.imagenUrl).where((u) => u != null && u.isNotEmpty).toList();

    // 1. Guardar en la tabla cotizaciones (únicamente fotos de proformas)
    try {
      int idx = 0;
      for (final cot in cotizaciones) {
        idx++;
        await _supabase.from('cotizaciones').insert({
          'id_solicitud': idSolicitud,
          'numero_proforma': idx,
          'ruta_imagen': cot.imagenUrl,
          'estado': 'PENDIENTE',
        });
      }
    } catch (e) {
      // ignore si no existe la tabla
    }

    // 2. Guardar las fotos en detalle_solicitud.ruta_imagen
    final fotoPrincipal = imagenPrincipalProforma ?? (urlsFotos.isNotEmpty ? urlsFotos.first : null);
    if (fotoPrincipal != null && fotoPrincipal.isNotEmpty) {
      try {
        await _supabase
            .from('detalle_solicitud')
            .update({'ruta_imagen': fotoPrincipal})
            .eq('id_solicitud', idSolicitud);
      } catch (_) {}
    }

    // 3. Guardar las fotos y nota en solicitudes.observacion manteniendo estado PENDIENTE
    final observacionFotos = urlsFotos.isNotEmpty
        ? '[COTIZACIONES_ENVIADAS] [PROFORMAS: ${urlsFotos.join("|||")}] Proformas enviadas a revisión'
        : '[COTIZACIONES_ENVIADAS] Cotizaciones recibidas y enviadas a revisión del Gerente';

    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'PENDIENTE',
          'observacion': observacionFotos,
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
    String? rutaImagenGanadora,
  }) async {
    // 1. Marcar la cotización seleccionada como 'AUTORIZADA' y las demás como 'RECHAZADA'
    try {
      await _supabase
          .from('cotizaciones')
          .update({'estado': 'RECHAZADA'})
          .eq('id_solicitud', idSolicitud);

      bool actualizada = false;

      if (idCotizacion != 0) {
        await _supabase
            .from('cotizaciones')
            .update({
              'estado': 'AUTORIZADA',
              'id_usuario_autorizador': idUsuarioGerente,
              'comentario_autorizacion': observacionGerente,
              if (rutaImagenGanadora != null && rutaImagenGanadora.isNotEmpty)
                'ruta_imagen': rutaImagenGanadora,
            })
            .eq('id_cotizacion', idCotizacion);
        actualizada = true;
      } else if (rutaImagenGanadora != null && rutaImagenGanadora.isNotEmpty) {
        final res = await _supabase
            .from('cotizaciones')
            .update({
              'estado': 'AUTORIZADA',
              'id_usuario_autorizador': idUsuarioGerente,
              'comentario_autorizacion': observacionGerente,
            })
            .eq('id_solicitud', idSolicitud)
            .eq('ruta_imagen', rutaImagenGanadora)
            .select();
        if ((res as List).isNotEmpty) {
          actualizada = true;
        }
      }

      if (!actualizada) {
        await _supabase.from('cotizaciones').insert({
          'id_solicitud': idSolicitud,
          'numero_proforma': 1,
          'ruta_imagen': rutaImagenGanadora,
          'estado': 'AUTORIZADA',
          'id_usuario_autorizador': idUsuarioGerente,
          'comentario_autorizacion': observacionGerente,
        });
      }
    } catch (_) {}

    // 2. Actualizar detalle_solicitud.ruta_imagen con la proforma ganadora
    if (rutaImagenGanadora != null && rutaImagenGanadora.isNotEmpty) {
      try {
        await _supabase
            .from('detalle_solicitud')
            .update({'ruta_imagen': rutaImagenGanadora})
            .eq('id_solicitud', idSolicitud);
      } catch (_) {}
    }

    // 3. Actualizar estado de la solicitud a 'APROBADA'
    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'APROBADA',
          'observacion': observacionGerente ?? 'Proforma autorizada por Gerente',
        })
        .eq('id_solicitud', idSolicitud);

    // 4. Registrar en aprobaciones
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
  // COMPRAS: MARCAR COMO COMPRADO Y ENVIAR A ALMACÉN
  // ============================================================
  Future<void> marcarComoComprado({
    required int idSolicitud,
    int? idUsuarioCompras,
    String? observacion,
  }) async {
    final obsFinal = observacion != null && observacion.trim().isNotEmpty
        ? '[COMPRADO] ${observacion.trim()}'
        : '[COMPRADO] Materiales adquiridos por Compras y transferidos a Almacén';

    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'COMPRADO',
          'observacion': obsFinal,
        })
        .eq('id_solicitud', idSolicitud);

    if (idUsuarioCompras != null && idUsuarioCompras != 0) {
      try {
        await _supabase.from('aprobaciones').insert({
          'id_solicitud': idSolicitud,
          'id_usuario': idUsuarioCompras,
          'estado': 'COMPRADO',
          'comentario': obsFinal,
        });
      } catch (_) {}
    }
  }
}
