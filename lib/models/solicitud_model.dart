import 'usuario_model.dart';
import 'piso_model.dart';
import 'detalle_solicitud_model.dart';

class SolicitudModel {
  final int idSolicitud;
  final PisoModel? piso;
  final UsuarioModel? usuario;
  final DateTime fecha;
  final String estado;
  final String? observacion;
  final List<DetalleSolicitudModel> detalles;

  SolicitudModel({
    required this.idSolicitud,
    this.piso,
    this.usuario,
    required this.fecha,
    required this.estado,
    this.observacion,
    this.detalles = const [],
  });

  factory SolicitudModel.fromMap(Map<String, dynamic> map) {
    return SolicitudModel(
      idSolicitud: map['id_solicitud'] as int,
      piso: map['pisos'] != null
          ? PisoModel.fromMap(Map<String, dynamic>.from(map['pisos']))
          : null,
      usuario: map['usuarios'] != null
          ? UsuarioModel.fromMap(Map<String, dynamic>.from(map['usuarios']))
          : null,
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'].toString())
          : DateTime.now(),
      estado: map['estado'] as String? ?? 'PENDIENTE',
      observacion: map['observacion'] as String?,
      detalles: map['detalle_solicitud'] != null
          ? (map['detalle_solicitud'] as List)
              .map((d) => DetalleSolicitudModel.fromMap(
                  Map<String, dynamic>.from(d)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_solicitud': idSolicitud,
      'id_piso': piso?.idPiso,
      'id_usuario': usuario?.idUsuario,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'observacion': observacion,
    };
  }
}