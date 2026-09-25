class MaterialModel {
  final int idMaterial;
  final String? codigo;
  final String nombre;
  final String unidadMedida;

  MaterialModel({
    required this.idMaterial,
    this.codigo,
    required this.nombre,
    this.unidadMedida = 'unid.',
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      idMaterial: map['id_material'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      unidadMedida: map['unidad_medida'] as String? ?? 'unid.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_material': idMaterial,
      'codigo': codigo,
      'nombre': nombre,
      'unidad_medida': unidadMedida,
    };
  }
}
