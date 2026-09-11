// lib/modules/compras/controller/compras_controller.dart
import 'dart:io';
import '../../../models/cotizacion_model.dart';
import '../../../models/solicitud_model.dart';
import '../service/compras_service.dart';

class ComprasController {
  final ComprasService _service = ComprasService();

  Future<List<SolicitudModel>> obtenerSolicitudesACotizar(int idObra) async {
    return await _service.obtenerSolicitudesACotizar(idObra);
  }

  Future<List<SolicitudModel>> obtenerSolicitudesEnviadasAGerente(int idObra) async {
    return await _service.obtenerSolicitudesEnviadasAGerente(idObra);
  }

  Future<List<SolicitudModel>> obtenerSolicitudesAprobadas(int idObra) async {
    return await _service.obtenerSolicitudesAprobadas(idObra);
  }

  Future<List<SolicitudModel>> obtenerTodasLasSolicitudesAdmin({int? idObraFiltro}) async {
    return await _service.obtenerTodasLasSolicitudesAdmin(idObraFiltro: idObraFiltro);
  }

  Future<List<CotizacionModel>> obtenerCotizacionesPorSolicitud(int idSolicitud) async {
    return await _service.obtenerCotizacionesPorSolicitud(idSolicitud);
  }

  Future<String?> subirImagenProforma({
    required File archivo,
    required int idSolicitud,
    required int indiceCotizacion,
  }) async {
    return await _service.subirImagenProforma(
      archivo: archivo,
      idSolicitud: idSolicitud,
      indiceCotizacion: indiceCotizacion,
    );
  }

  Future<void> guardarCotizacionesYEnviarAGerente({
    required int idSolicitud,
    required int idUsuarioCompras,
    required List<CotizacionModel> cotizaciones,
    String? imagenPrincipalProforma,
  }) async {
    await _service.guardarCotizacionesYEnviarAGerente(
      idSolicitud: idSolicitud,
      idUsuarioCompras: idUsuarioCompras,
      cotizaciones: cotizaciones,
      imagenPrincipalProforma: imagenPrincipalProforma,
    );
  }

  Future<void> autorizarCotizacion({
    required int idSolicitud,
    required int idCotizacion,
    required int idUsuarioGerente,
    String? observacionGerente,
  }) async {
    await _service.autorizarCotizacion(
      idSolicitud: idSolicitud,
      idCotizacion: idCotizacion,
      idUsuarioGerente: idUsuarioGerente,
      observacionGerente: observacionGerente,
    );
  }

  Future<void> marcarComoComprado({
    required int idSolicitud,
    String? observacion,
  }) async {
    await _service.marcarComoComprado(
      idSolicitud: idSolicitud,
      observacion: observacion,
    );
  }
}
