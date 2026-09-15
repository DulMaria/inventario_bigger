// lib/modules/almacen/controller/almacen_controller.dart
import '../../../models/solicitud_model.dart';
import '../service/almacen_service.dart';

class AlmacenController {
  final AlmacenService _service = AlmacenService();

  Future<List<SolicitudModel>> obtenerMaterialesEnAlmacen(int idObra) async {
    return await _service.obtenerMaterialesEnAlmacen(idObra);
  }

  Future<List<SolicitudModel>> obtenerMaterialesEntregados(int idObra) async {
    return await _service.obtenerMaterialesEntregados(idObra);
  }

  Future<List<SolicitudModel>> obtenerTodosMaterialesEnAlmacenAdmin({int? idObraFiltro}) async {
    return await _service.obtenerTodosMaterialesEnAlmacenAdmin(idObraFiltro: idObraFiltro);
  }

  Future<List<SolicitudModel>> obtenerTodosMaterialesEntregadosAdmin({int? idObraFiltro}) async {
    return await _service.obtenerTodosMaterialesEntregadosAdmin(idObraFiltro: idObraFiltro);
  }

  Future<void> marcarComoEntregado({
    required int idSolicitud,
    int? idUsuarioAlmacen,
    String? observacion,
  }) async {
    await _service.marcarComoEntregado(
      idSolicitud: idSolicitud,
      idUsuarioAlmacen: idUsuarioAlmacen,
      observacion: observacion,
    );
  }
}
