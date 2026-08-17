class ObraModel {
  final int idObra;
  final String nombre;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final bool estado;

  ObraModel({
    required this.idObra,
    required this.nombre,
    this.direccion,
    this.latitud,
    this.longitud,
    required this.estado,
  });

  factory ObraModel.fromMap(Map<String, dynamic> map) {
    return ObraModel(
      idObra: map['id_obra'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      latitud: map['latitud'] != null
          ? (map['latitud'] as num).toDouble()
          : null,
      longitud: map['longitud'] != null
          ? (map['longitud'] as num).toDouble()
          : null,
      estado: map['estado'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obra': idObra,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
    };
  }
}
