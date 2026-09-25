import 'material_model.dart';
import 'solicitud_model.dart';

class DetalleSolicitudModel {
  final int idDetalle;
  final SolicitudModel? solicitud;
  MaterialModel? material;
  final int cantidad;
  final String unidadMedida;
  final String? rutaImagen;
  final int? idMaterial;

  DetalleSolicitudModel({
    required this.idDetalle,
    this.solicitud,
    this.material,
    required this.cantidad,
    this.unidadMedida = 'unid.',
    this.rutaImagen,
    this.idMaterial,
  });

  factory DetalleSolicitudModel.fromMap(Map<String, dynamic> map) {
    final parsedMaterial = map['materiales'] != null
        ? MaterialModel.fromMap(Map<String, dynamic>.from(map['materiales']))
        : (map['material'] != null
            ? MaterialModel.fromMap(Map<String, dynamic>.from(map['material']))
            : null);

    final rawIdMat = map['id_material'] != null
        ? (map['id_material'] as num).toInt()
        : parsedMaterial?.idMaterial;

    final unit = map['unidad_medida'] as String? ?? parsedMaterial?.unidadMedida ?? 'unid.';

    return DetalleSolicitudModel(
      idDetalle: map['id_detalle'] as int,
      solicitud: map['solicitudes'] != null
          ? SolicitudModel.fromMap(Map<String, dynamic>.from(map['solicitudes']))
          : null,
      material: parsedMaterial,
      cantidad: (map['cantidad'] as num).toInt(),
      unidadMedida: unit,
      rutaImagen: map['ruta_imagen'] as String?,
      idMaterial: rawIdMat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_detalle': idDetalle,
      'id_solicitud': solicitud?.idSolicitud,
      'id_material': idMaterial ?? material?.idMaterial,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'ruta_imagen': rutaImagen,
    };
  }
}