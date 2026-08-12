import 'solicitud_model.dart';

class EntregaMaterialModel {
  final int idEntrega;
  final SolicitudModel solicitud;
  final DateTime fechaLlegada;
  final String estado;
  final String? observacion;

  EntregaMaterialModel({
    required this.idEntrega,
    required this.solicitud,
    required this.fechaLlegada,
    required this.estado,
    this.observacion,
  });

  factory EntregaMaterialModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return EntregaMaterialModel(
      idEntrega: map['id_entrega'],
      solicitud: SolicitudModel.fromMap(map['solicitudes']),
      fechaLlegada: DateTime.parse(map['fecha_llegada']),
      estado: map['estado'] ?? 'PENDIENTE',
      observacion: map['observacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_entrega': idEntrega,
      'id_solicitud': solicitud.idSolicitud,
      'fecha_llegada': fechaLlegada.toIso8601String(),
      'estado': estado,
      'observacion': observacion,
    };
  }
}