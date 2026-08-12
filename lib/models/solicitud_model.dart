import 'usuario_model.dart';
import 'piso_model.dart';

class SolicitudModel {
  final int idSolicitud;
  final PisoModel piso;
  final UsuarioModel usuario;
  final DateTime fecha;
  final String estado;
  final String? observacion;

  SolicitudModel({
    required this.idSolicitud,
    required this.piso,
    required this.usuario,
    required this.fecha,
    required this.estado,
    this.observacion,
  });

  factory SolicitudModel.fromMap(Map<String, dynamic> map) {
    return SolicitudModel(
      idSolicitud: map['id_solicitud'],
      piso: PisoModel.fromMap(map['pisos']),
      usuario: UsuarioModel.fromMap(map['usuarios']),
      fecha: DateTime.parse(map['fecha']),
      estado: map['estado'] ?? 'PENDIENTE',
      observacion: map['observacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_solicitud': idSolicitud,
      'id_piso': piso.idPiso,
      'id_usuario': usuario.idUsuario,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'observacion': observacion,
    };
  }
}