import 'solicitud_model.dart';
import 'usuario_model.dart';

class AprobacionModel {
  final int idAprobacion;
  final SolicitudModel solicitud;
  final UsuarioModel usuario;
  final DateTime fecha;
  final String estado;
  final String? comentario;

  AprobacionModel({
    required this.idAprobacion,
    required this.solicitud,
    required this.usuario,
    required this.fecha,
    required this.estado,
    this.comentario,
  });

  factory AprobacionModel.fromMap(Map<String, dynamic> map) {
    return AprobacionModel(
      idAprobacion: map['id_aprobacion'],
      solicitud: SolicitudModel.fromMap(map['solicitudes']),
      usuario: UsuarioModel.fromMap(map['usuarios']),
      fecha: DateTime.parse(map['fecha']),
      estado: map['estado'],
      comentario: map['comentario'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_aprobacion': idAprobacion,
      'id_solicitud': solicitud.idSolicitud,
      'id_usuario': usuario.idUsuario,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'comentario': comentario,
    };
  }
}