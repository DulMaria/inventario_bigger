import 'solicitud_model.dart';
import 'usuario_model.dart';

class AuditoriaModel {
  final int idAuditoria;
  final UsuarioModel usuario;
  final SolicitudModel? solicitud;
  final String accion;
  final String? descripcion;
  final DateTime fecha;

  AuditoriaModel({
    required this.idAuditoria,
    required this.usuario,
    this.solicitud,
    required this.accion,
    this.descripcion,
    required this.fecha,
  });

  factory AuditoriaModel.fromMap(Map<String, dynamic> map) {
    return AuditoriaModel(
      idAuditoria: map['id_auditoria'],
      usuario: UsuarioModel.fromMap(map['usuarios']),
      solicitud: map['solicitudes'] != null
          ? SolicitudModel.fromMap(map['solicitudes'])
          : null,
      accion: map['accion'],
      descripcion: map['descripcion'],
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_auditoria': idAuditoria,
      'id_usuario': usuario.idUsuario,
      'id_solicitud': solicitud?.idSolicitud,
      'accion': accion,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }
}