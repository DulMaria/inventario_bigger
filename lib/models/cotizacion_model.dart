// lib/models/cotizacion_model.dart

class CotizacionModel {
  final int? idCotizacion;
  final int idSolicitud;
  final int? idUsuario;
  final String? imagenUrl;
  final String estado; // 'PENDIENTE', 'SELECCIONADA', 'RECHAZADA'
  final DateTime? fecha;

  CotizacionModel({
    this.idCotizacion,
    required this.idSolicitud,
    this.idUsuario,
    this.imagenUrl,
    this.estado = 'PENDIENTE',
    this.fecha,
  });

  factory CotizacionModel.fromMap(Map<String, dynamic> map) {
    return CotizacionModel(
      idCotizacion: map['id_cotizacion'] as int?,
      idSolicitud: (map['id_solicitud'] as num).toInt(),
      idUsuario: map['id_usuario'] as int?,
      imagenUrl: map['imagen_url'] as String?,
      estado: map['estado']?.toString() ?? 'PENDIENTE',
      fecha: map['fecha'] != null ? DateTime.tryParse(map['fecha'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idCotizacion != null) 'id_cotizacion': idCotizacion,
      'id_solicitud': idSolicitud,
      if (idUsuario != null) 'id_usuario': idUsuario,
      'imagen_url': imagenUrl,
      'estado': estado,
      if (fecha != null) 'fecha': fecha!.toIso8601String(),
    };
  }
}
