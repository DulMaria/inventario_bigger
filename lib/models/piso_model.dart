import 'obra_model.dart';

class PisoModel {
  final int idPiso;
  final ObraModel obra;
  final String? nombre;
  final String estadoObra;
  final String tipoPiso;
  final int numeroPiso;
  final bool estado;

  PisoModel({
    required this.idPiso,
    required this.obra,
    this.nombre,
    required this.estadoObra,
    required this.tipoPiso,
    required this.numeroPiso,
    required this.estado,
  });

  factory PisoModel.fromMap(Map<String, dynamic> map) {
    return PisoModel(
      idPiso: map['id_piso'] as int,
      obra: map['obras'] != null
          ? ObraModel.fromMap(Map<String, dynamic>.from(map['obras']))
          : ObraModel(
              idObra: map['id_obra'] as int,
              nombre: 'Obra',
              direccion: null,
              latitud: null,
              longitud: null,
              estado: true,
            ),
      nombre: map['nombre'] as String?,
      estadoObra: map['estado_obra'] as String? ?? 'NO INICIADO',
      tipoPiso: map['tipo_piso'] as String? ?? 'NORMAL',
      numeroPiso: (map['numero_piso'] as int?) ?? 1,
      estado: map['estado'] as bool? ?? true,
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
