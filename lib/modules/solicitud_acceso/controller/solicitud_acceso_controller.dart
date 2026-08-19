import '../../../models/obra_model.dart';
import '../../../models/solicitud_acceso_model.dart';
import '../service/solicitud_acceso_service.dart';

class SolicitudAccesoController {
  final SolicitudAccesoService _service = SolicitudAccesoService();

  // ============================================================
  // OBTENER OBRAS DISPONIBLES
  // ============================================================

  Future<List<ObraModel>> obtenerObrasDisponibles() async {
    return await _service.obtenerObrasDisponibles();
  }

  // ============================================================
  // OBTENER ROLES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerRoles() async {
    return await _service.obtenerRoles();
  }

  // ============================================================
  // SOLICITAR ACCESO
  // ============================================================

  Future<String?> solicitarAcceso({
    required int idObra,
    required int idRolSolicitado,
  }) async {
    if (idObra <= 0) {
      return 'Selecciona una obra';
    }

    if (idRolSolicitado <= 0) {
      return 'Selecciona un rol';
    }

    try {
      await _service.solicitarAcceso(
        idObra: idObra,
        idRolSolicitado: idRolSolicitado,
      );

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ============================================================
  // OBTENER MIS SOLICITUDES
  // ============================================================

  Future<List<SolicitudAccesoModel>> obtenerMisSolicitudes() async {
    return await _service.obtenerMisSolicitudes();
  }
}
