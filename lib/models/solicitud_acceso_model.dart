class SolicitudAccesoModel {
  final int idSolicitudAcceso;
  final int idUsuario;
  final int idObra;
  final int idRolSolicitado;
  final int? idRolAprobado;
  final String estado;
  final String? observacion;
  final DateTime fecha;

  SolicitudAccesoModel({
    required this.idSolicitudAcceso,
    required this.idUsuario,
    required this.idObra,
    required this.idRolSolicitado,
    this.idRolAprobado,
    required this.estado,
    this.observacion,
    required this.fecha,
  });

  factory SolicitudAccesoModel.fromMap(Map<String, dynamic> map) {
    return SolicitudAccesoModel(
      idSolicitudAcceso: map['id_solicitud_acceso'],
      idUsuario: map['id_usuario'],
      idObra: map['id_obra'],
      idRolSolicitado: map['id_rol_solicitado'],
      idRolAprobado: map['id_rol_aprobado'],
      estado: map['estado'] ?? 'PENDIENTE',
      observacion: map['observacion'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
