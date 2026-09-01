import '../service/solicitud_obrero_service.dart';
import '../../../models/solicitud_obrero_model.dart';

class SolicitudObreroController {
  final SolicitudObreroService _service = SolicitudObreroService();

  // ============================================================
  // CREAR SOLICITUD DE OBRERO
  // ============================================================

  Future<void> crearSolicitudObrero({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('Debes añadir al menos un material a la solicitud.');
    }

    await _service.crearSolicitudObrero(
      idPiso: idPiso,
      idUsuario: idUsuario,
      materiales: materiales,
    );
  }

  // ============================================================
  // OBTENER SOLICITUDES DEL OBRERO POR PISO
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPorPiso({
    required int idPiso,
    required int idUsuario,
  }) async {
    return await _service.obtenerSolicitudesPorPiso(
      idPiso: idPiso,
      idUsuario: idUsuario,
    );
  }

  // ============================================================
  // OBTENER SOLICITUDES DEL OBRERO POR OBRA
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerMisSolicitudes({
    required int idUsuario,
    required int idObra,
  }) async {
    return await _service.obtenerSolicitudesPorUsuario(
      idUsuario: idUsuario,
      idObra: idObra,
    );
  }

  // ============================================================
  // TÉCNICO: OBTENER SOLICITUDES PENDIENTES
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerSolicitudesPendientes(
    int idObra,
  ) async {
    return await _service.obtenerSolicitudesPendientesPorObra(idObra);
  }

  // ============================================================
  // HISTORIAL COMPLETO
  // ============================================================

  Future<List<SolicitudObreroModel>> obtenerTodas(int idObra) async {
    return await _service.obtenerTodasPorObra(idObra);
  }

  // ============================================================
  // TÉCNICO: APROBAR SOLICITUD
  // ============================================================

  Future<void> aprobarSolicitud({
    required int idSolicitudObrero,
    required int idPiso,
    required int idTecnicoUsuario,
    required List<Map<String, dynamic>> materiales,
    String? observacion,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('La solicitud debe tener al menos un material aprobado.');
    }

    await _service.aprobarYSometerACompras(
      idSolicitudObrero: idSolicitudObrero,
      idPiso: idPiso,
      idTecnicoUsuario: idTecnicoUsuario,
      materiales: materiales,
      observacion: observacion,
    );
  }

  // ============================================================
  // TÉCNICO: RECHAZAR SOLICITUD
  // ============================================================

  Future<void> rechazarSolicitud({
    required int idSolicitudObrero,
    required String observacion,
  }) async {
    final motivoLimpio = observacion.trim();
    if (motivoLimpio.isEmpty) {
      throw Exception('Por favor ingresa un motivo para el rechazo.');
    }

    await _service.rechazarSolicitudObrero(
      idSolicitudObrero: idSolicitudObrero,
      observacion: motivoLimpio,
    );
  }
}
