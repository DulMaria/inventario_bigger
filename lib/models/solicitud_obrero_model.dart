import 'piso_model.dart';
import 'usuario_model.dart';
import 'material_model.dart';

class SolicitudObreroModel {
  final int idSolicitudObrero;
  final int idPiso;
  final int idUsuario;
  final DateTime fecha;
  final String estado;
  final String? observacion;
  final int? idSolicitudCreada;
  final PisoModel? piso;
  final UsuarioModel? usuario;
  final List<DetalleSolicitudObreroModel> detalles;

  SolicitudObreroModel({
    required this.idSolicitudObrero,
    required this.idPiso,
    required this.idUsuario,
    required this.fecha,
    required this.estado,
    this.observacion,
    this.idSolicitudCreada,
    this.piso,
    this.usuario,
    this.detalles = const [],
  });

  factory SolicitudObreroModel.fromMap(Map<String, dynamic> map) {
    return SolicitudObreroModel(
      idSolicitudObrero: map['id_solicitud_obrero'] as int,
      idPiso: map['id_piso'] as int,
      idUsuario: map['id_usuario'] as int,
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'].toString())
          : DateTime.now(),
      estado: map['estado'] as String? ?? 'PENDIENTE_REVISION',
      observacion: map['observacion'] as String?,
      idSolicitudCreada: map['id_solicitud_creada'] as int?,
      piso: map['pisos'] != null
          ? PisoModel.fromMap(Map<String, dynamic>.from(map['pisos']))
          : null,
      usuario: map['usuarios'] != null
          ? UsuarioModel.fromMap(Map<String, dynamic>.from(map['usuarios']))
          : null,
      detalles: map['detalle_solicitud_obrero'] != null
          ? (map['detalle_solicitud_obrero'] as List)
              .map((d) => DetalleSolicitudObreroModel.fromMap(
                  Map<String, dynamic>.from(d)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_solicitud_obrero': idSolicitudObrero,
      'id_piso': idPiso,
      'id_usuario': idUsuario,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'observacion': observacion,
      'id_solicitud_creada': idSolicitudCreada,
    };
  }
}

class DetalleSolicitudObreroModel {
  final int idDetalleObrero;
  final int idSolicitudObrero;
  final int idMaterial;
  final int cantidad;
  final String? rutaImagen;
  final MaterialModel? material;

  DetalleSolicitudObreroModel({
    required this.idDetalleObrero,
    required this.idSolicitudObrero,
    required this.idMaterial,
    required this.cantidad,
    this.rutaImagen,
    this.material,
  });

  factory DetalleSolicitudObreroModel.fromMap(Map<String, dynamic> map) {
    return DetalleSolicitudObreroModel(
      idDetalleObrero: map['id_detalle_obrero'] as int,
      idSolicitudObrero: map['id_solicitud_obrero'] as int,
      idMaterial: map['id_material'] as int,
      cantidad: map['cantidad'] as int,
      rutaImagen: map['ruta_imagen'] as String?,
      material: map['materiales'] != null
          ? MaterialModel.fromMap(Map<String, dynamic>.from(map['materiales']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_detalle_obrero': idDetalleObrero,
      'id_solicitud_obrero': idSolicitudObrero,
      'id_material': idMaterial,
      'cantidad': cantidad,
      'ruta_imagen': rutaImagen,
    };
  }
}
