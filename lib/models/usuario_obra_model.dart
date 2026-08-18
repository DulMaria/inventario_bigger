class UsuarioObraModel {
  final int idUsuarioObra;
  final int idUsuario;
  final int idObra;
  final int idRol;
  final bool estado;
  final String? nombreObra;
  final String? nombreRol;

  UsuarioObraModel({
    required this.idUsuarioObra,
    required this.idUsuario,
    required this.idObra,
    required this.idRol,
    required this.estado,
    this.nombreObra,
    this.nombreRol,
  });

  factory UsuarioObraModel.fromMap(Map<String, dynamic> map) {
    return UsuarioObraModel(
      idUsuarioObra: map['id_usuario_obra'],
      idUsuario: map['id_usuario'],
      idObra: map['id_obra'],
      idRol: map['id_rol'],
      estado: map['estado'] ?? false,
      nombreObra: map['obras']?['nombre'],
      nombreRol: map['roles']?['nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario_obra': idUsuarioObra,
      'id_usuario': idUsuario,
      'id_obra': idObra,
      'id_rol': idRol,
      'estado': estado,
      'nombreObra': nombreObra,
      'nombreRol': nombreRol,
    };
  }
}
