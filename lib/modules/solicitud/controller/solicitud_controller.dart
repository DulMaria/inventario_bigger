import '../service/solicitud_service.dart';

class SolicitudController {
  final SolicitudService _service = SolicitudService();

  Future<void> crearSolicitud({
    required int idPiso,
    required int idUsuario,
    required List<Map<String, dynamic>> materiales,
  }) async {
    if (materiales.isEmpty) {
      throw Exception('Debes añadir al menos un material a la solicitud.');
    }

    await _service.crearSolicitud(
      idPiso: idPiso,
      idUsuario: idUsuario,
      materiales: materiales,
    );
  }
}
