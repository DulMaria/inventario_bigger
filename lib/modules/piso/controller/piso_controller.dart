import '../service/piso_service.dart';
import '../../../models/piso_model.dart';

class PisoController {
  final PisoService _pisoService = PisoService();

  // Crear piso
  Future<PisoModel> crearPiso({
    required int idObra,
    required String nombre,
  }) async {
    return await _pisoService.crearPiso(
      idObra: idObra,
      nombre: nombre,
    );
  }

  // Obtener pisos de una obra
  Future<List<PisoModel>> obtenerPisos(int idObra) async {
    return await _pisoService.obtenerPisos(idObra);
  }

  // Editar piso
  Future<PisoModel> editarPiso({
    required int idPiso,
    required String nombre,
    required String estadoObra,
  }) async {
    return await _pisoService.editarPiso(
      idPiso: idPiso,
      nombre: nombre,
      estadoObra: estadoObra,
    );
  }
}