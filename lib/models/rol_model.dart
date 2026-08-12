class RolModel {
  final int idRol;
  final String nombre;

  RolModel({
    required this.idRol,
    required this.nombre,
  });

  factory RolModel.fromMap(Map<String, dynamic> map) {
    return RolModel(
      idRol: map['id_rol'],
      nombre: map['nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_rol': idRol,
      'nombre': nombre,
    };
  }
}