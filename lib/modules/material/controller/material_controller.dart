import '../../../models/material_model.dart';
import '../service/material_service.dart';

class MaterialController {
  final MaterialService _service = MaterialService();

  Future<List<MaterialModel>> obtenerMateriales() async {
    try {
      return await _service.obtenerMateriales();
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MaterialModel?> buscarMaterial(String nombre) async {
    if (nombre.trim().isEmpty) {
      throw Exception('Ingresa el nombre del material');
    }

    try {
      return await _service.buscarMaterial(nombre.trim());
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MaterialModel> crearMaterial(String nombre) async {
    if (nombre.trim().isEmpty) {
      throw Exception('Ingresa el nombre del material');
    }

    try {
      return await _service.crearMaterial(nombre: nombre.trim());
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
