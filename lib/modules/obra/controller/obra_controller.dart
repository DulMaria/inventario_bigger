import '../../../models/obra_model.dart';
import '../service/obra_service.dart';

class ObraController {
  final ObraService _obraService = ObraService();

  Future<ObraModel> crearObra({
    required String nombre,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    return await _obraService.crearObra(
      nombre: nombre,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
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

  Future<bool> existeObraConNombre(String nombre) async {
    return await _obraService.existeObraConNombre(nombre);
  }
}