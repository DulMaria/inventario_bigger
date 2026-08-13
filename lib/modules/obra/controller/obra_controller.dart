import '../../../models/obra_model.dart';
import '../service/obra_service.dart';

class ObraController {
  final ObraService _obraService = ObraService();

  Future<ObraModel> crearObra({
    required String nombre,
    required String direccion,
  }) {
    return _obraService.crearObra(
      nombre: nombre,
      direccion: direccion,
    );
  }

  Future<List<ObraModel>> obtenerObras() {
    return _obraService.obtenerObras();
  }

  Future<ObraModel> editarObra({
    required int idObra,
    required String nombre,
    required String direccion,
  }) {
    return _obraService.editarObra(
      idObra: idObra,
      nombre: nombre,
      direccion: direccion,
    );
  }
}