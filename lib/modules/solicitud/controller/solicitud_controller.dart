import '../service/solicitud_service.dart';
import '../../../models/solicitud_model.dart';

class SolicitudController {
  final SolicitudService _service = SolicitudService();

  Future<void> crearSolicitud({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
    String? observacion,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('Debes añadir al menos un material a la solicitud.');
    }

    await _service.crearSolicitud(
      idPiso: idPiso,
      idUsuario: idUsuario,
      materiales: materiales,
      observacion: observacion,
    );
  }

  Future<List<SolicitudModel>> obtenerSolicitudesPorPiso({
    required int idPiso,
    required int idUsuario,
  }) async {
    return await _service.obtenerSolicitudesPorPiso(
      idPiso: idPiso,
      idUsuario: idUsuario,
    );
  }

  Future<List<SolicitudModel>> obtenerMisSolicitudes({
    required int idUsuario,
    required int idObra,
  }) async {
    return await _service.obtenerSolicitudesPorUsuario(
      idUsuario: idUsuario,
      idObra: idObra,
    );
  }

  Future<List<SolicitudModel>> obtenerTodas(int idObra) async {
    return await _service.obtenerTodasPorObra(idObra);
  }
}
