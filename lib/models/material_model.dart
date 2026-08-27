class MaterialModel {
  final int idMaterial;
  final String? codigo;
  final String nombre;

  MaterialModel({required this.idMaterial, this.codigo, required this.nombre});

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      idMaterial: map['id_material'],
      codigo: map['codigo'],
      nombre: map['nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id_material': idMaterial, 'codigo': codigo, 'nombre': nombre};
  }
}
