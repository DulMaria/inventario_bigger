import 'material_model.dart';
import 'solicitud_model.dart';

class DetalleSolicitudModel {
  final int idDetalle;
  final SolicitudModel? solicitud;
  final MaterialModel? material;
  final int cantidad;
  final String? rutaImagen;

  DetalleSolicitudModel({
    required this.idDetalle,
    this.solicitud,
    this.material,
    required this.cantidad,
    this.rutaImagen,
  });

  factory DetalleSolicitudModel.fromMap(Map<String, dynamic> map) {
    return DetalleSolicitudModel(
      idDetalle: map['id_detalle'] as int,
      solicitud: map['solicitudes'] != null
          ? SolicitudModel.fromMap(Map<String, dynamic>.from(map['solicitudes']))
          : null,
      material: map['materiales'] != null
          ? MaterialModel.fromMap(Map<String, dynamic>.from(map['materiales']))
          : null,
      cantidad: (map['cantidad'] as num).toInt(),
      rutaImagen: map['ruta_imagen'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_detalle': idDetalle,
      'id_solicitud': solicitud?.idSolicitud,
      'id_material': material?.idMaterial,
      'cantidad': cantidad,
      'ruta_imagen': rutaImagen,
    };
  }
}