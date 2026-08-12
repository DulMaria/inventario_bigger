class MaterialModel {
  final int idMaterial;
  final String? codigo;
  final String nombre;
  final String unidad;

  MaterialModel({
    required this.idMaterial,
    this.codigo,
    required this.nombre,
    required this.unidad,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      idMaterial: map['id_material'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      unidad: map['unidad'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_material': idMaterial,
      'codigo': codigo,
      'nombre': nombre,
      'unidad': unidad,
    };
  }
}