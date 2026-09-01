// lib/modules/solicitud_acceso/controller/solicitud_acceso_controller.dart
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
  // OBTENER OBRAS APROBADAS
  // ============================================================
  Future<List<ObraModel>> obtenerObrasAprobadas() async {
    return await _service.obtenerObrasAprobadas();
  }

  // ============================================================
  // OBTENER MIS OBRAS
  // ============================================================
  Future<List<ObraModel>> obtenerMisObras() async {
    return await _service.obtenerMisObras();
  }

  // ============================================================
  // OBTENER ROL EN UNA OBRA
  // ============================================================
  Future<int?> obtenerRolEnObra(int idObra) async {
    return await _service.obtenerRolEnObra(idObra);
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

  // ============================================================
  // OBTENER SOLICITUDES PARA EL GERENTE
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    return await _service.obtenerSolicitudes();
  }

  // ============================================================
  // ✅ NUEVO: OBTENER TODAS LAS SOLICITUDES (PARA ADMIN)
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerTodasLasSolicitudes() async {
    return await _service.obtenerTodasLasSolicitudes();
  }

  // ============================================================
  // APROBAR SOLICITUD
  // ============================================================
  Future<String?> aprobarSolicitud({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    try {
      await _service.aprobarSolicitud(
        idSolicitud: idSolicitud,
        idUsuario: idUsuario,
        idObra: idObra,
        idRol: idRol,
      );

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ============================================================
  // RECHAZAR SOLICITUD
  // ============================================================
  Future<String?> rechazarSolicitud({
    required int idSolicitud,
    String? observacion,
  }) async {
    try {
      await _service.rechazarSolicitud(
        idSolicitud: idSolicitud,
        observacion: observacion,
      );

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ============================================================
  // APROBAR CON OTRO ROL
  // ============================================================
  Future<String?> aprobarConRol({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    try {
      await _service.aprobarConRol(
        idSolicitud: idSolicitud,
        idUsuario: idUsuario,
        idObra: idObra,
        idRol: idRol,
      );

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}