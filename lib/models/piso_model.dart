import 'obra_model.dart';

class PisoModel {
  final int idPiso;
  final ObraModel obra;
  final String? nombre;
  final String estadoObra;
  final String tipoPiso;
  final int? numeroPiso;
  final bool estado;

  PisoModel({
    required this.idPiso,
    required this.obra,
    this.nombre,
    required this.estadoObra,
    required this.tipoPiso,
    this.numeroPiso,
    required this.estado,
  });

  factory PisoModel.fromMap(Map<String, dynamic> map) {
    return PisoModel(
      idPiso: map['id_piso'],
      obra: ObraModel.fromMap(map['obras']),
      nombre: map['nombre'],
      estadoObra: map['estado_obra'] ?? 'NO INICIADO',
      tipoPiso: map['tipo_piso'] ?? 'NORMAL',
      numeroPiso: map['numero_piso'] as int?,
      estado: map['estado'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_piso': idPiso,
      'id_obra': obra.idObra,
      'nombre': nombre,
      'estado_obra': estadoObra,
      'tipo_piso': tipoPiso,
      'numero_piso': numeroPiso,
      'estado': estado,
    };
  }
}
