class ObraModel {
  final int idObra;
  final String nombre;
  final String? direccion;
  final String estado;

  ObraModel({
    required this.idObra,
    required this.nombre,
    this.direccion,
    required this.estado,
  });

  factory ObraModel.fromMap(Map<String, dynamic> map) {
    return ObraModel(
      idObra: map['id_obra'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      estado: map['estado'] ?? 'ACTIVA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obra': idObra,
      'nombre': nombre,
      'direccion': direccion,
      'estado': estado,
    };
  }
}