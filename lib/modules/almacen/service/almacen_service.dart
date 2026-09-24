import 'package:inventario_bigger/core/config/app_colors.dart';
// lib/modules/almacen/service/almacen_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/solicitud_model.dart';
import '../../../models/material_model.dart';
import '../../../models/detalle_solicitud_model.dart';

class AlmacenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ENRIQUECER MATERIALES (Fallback en caso de políticas RLS)
  // ============================================================
  Future<List<SolicitudModel>> _enriquecerMateriales(List<SolicitudModel> solicitudes) async {
    for (final s in solicitudes) {
      if (s.detalles.isEmpty) {
        try {
          final resDetalles = await _supabase
              .from('detalle_solicitud')
              .select('*')
              .eq('id_solicitud', s.idSolicitud);

          final listaDetalles = (resDetalles as List)
              .map((d) => DetalleSolicitudModel.fromMap(Map<String, dynamic>.from(d)))
              .toList();

          for (final d in listaDetalles) {
            final matId = d.idMaterial ?? 0;
            if (matId != 0) {
              try {
                final resMat = await _supabase
                    .from('materiales')
                    .select('*')
                    .eq('id_material', matId)
                    .maybeSingle();

                if (resMat != null) {
                  d.material = MaterialModel.fromMap(Map<String, dynamic>.from(resMat));
                }
              } catch (_) {}
            }
          }
          s.detalles.addAll(listaDetalles);
        } catch (_) {}
      } else {
        for (final d in s.detalles) {
          if (d.material == null && (d.idMaterial ?? 0) != 0) {
            try {
              final resMat = await _supabase
                  .from('materiales')
                  .select('*')
                  .eq('id_material', d.idMaterial!)
                  .maybeSingle();
              if (resMat != null) {
                d.material = MaterialModel.fromMap(Map<String, dynamic>.from(resMat));
              }
            } catch (_) {}
          }
        }
      }
    }
    return solicitudes;
  }

  // ============================================================
  // OBTENER MATERIALES DISPONIBLES EN ALMACÉN (Estado: COMPRADO)
  // ============================================================
  Future<List<SolicitudModel>> obtenerMaterialesEnAlmacen(int idObra) async {
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
  // OBTENER HISTORIAL DE ENTREGAS (Estado: ENTREGADO)
  // ============================================================
  Future<List<SolicitudModel>> obtenerMaterialesEntregados(int idObra) async {
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
        .eq('estado', 'ENTREGADO')
        .order('fecha', ascending: false);

    final lista = (respuesta as List)
        .map((s) => SolicitudModel.fromMap(s as Map<String, dynamic>))
        .toList();

    return await _enriquecerMateriales(lista);
  }

  // ============================================================
  // OBTENER MATERIALES DISPONIBLES EN ALMACÉN GLOBAL (ADMIN)
  // ============================================================
  Future<List<SolicitudModel>> obtenerTodosMaterialesEnAlmacenAdmin({int? idObraFiltro}) async {
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
        ''').eq('estado', 'COMPRADO');

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
  // OBTENER HISTORIAL DE ENTREGAS GLOBAL (ADMIN)
  // ============================================================
  Future<List<SolicitudModel>> obtenerTodosMaterialesEntregadosAdmin({int? idObraFiltro}) async {
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
        ''').eq('estado', 'ENTREGADO');

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
  // MARCAR SOLICITUD COMO ENTREGADA A OBRERO / DESPACHADA
  // ============================================================
  Future<void> marcarComoEntregado({
    required int idSolicitud,
    int? idUsuarioAlmacen,
    String? observacion,
  }) async {
    final obsFinal = observacion != null && observacion.trim().isNotEmpty
        ? '[ENTREGADO] ${observacion.trim()}'
        : '[ENTREGADO] Material despachado y entregado por Almacén';

    await _supabase
        .from('solicitudes')
        .update({
          'estado': 'ENTREGADO',
          'observacion': obsFinal,
        })
        .eq('id_solicitud', idSolicitud);

    if (idUsuarioAlmacen != null && idUsuarioAlmacen != 0) {
      try {
        await _supabase.from('aprobaciones').insert({
          'id_solicitud': idSolicitud,
          'id_usuario': idUsuarioAlmacen,
          'estado': 'ENTREGADO',
          'comentario': obsFinal,
        });
      } catch (_) {}
    }
  }
}
