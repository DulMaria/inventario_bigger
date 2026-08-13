import 'obra_model.dart';

class PisoModel {
  final int idPiso;
  final ObraModel obra;
  final String? nombre;
  final String estadoObra;

  PisoModel({
    required this.idPiso,
    required this.obra,
    this.nombre,
    required this.estadoObra,
  });

  factory PisoModel.fromMap(Map<String, dynamic> map) {
    return PisoModel(
      idPiso: map['id_piso'],
      obra: ObraModel.fromMap(map['obras']),
      nombre: map['nombre'],
      estadoObra: map['estado_obra'] ?? 'NO INICIADO',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_piso': idPiso,
      'id_obra': obra.idObra,
      'nombre': nombre,
      'estado_obra': estadoObra,
    };
  }
}