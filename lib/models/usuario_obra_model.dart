class UsuarioObraModel {
  final int idUsuarioObra;
  final int idUsuario;
  final int idObra;
  final int idRol;
  final bool estado;

  UsuarioObraModel({
    required this.idUsuarioObra,
    required this.idUsuario,
    required this.idObra,
    required this.idRol,
    required this.estado,
  });

  factory UsuarioObraModel.fromMap(Map<String, dynamic> map) {
    return UsuarioObraModel(
      idUsuarioObra: map['id_usuario_obra'],
      idUsuario: map['id_usuario'],
      idObra: map['id_obra'],
      idRol: map['id_rol'],
      estado: map['estado'] ?? false,
    );
  }
}
