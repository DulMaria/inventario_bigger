class UsuarioModel {
  final int idUsuario;
  final String idAuth;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final bool estado;

  UsuarioModel({
    required this.idUsuario,
    required this.idAuth,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.telefono,
    required this.estado,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      idUsuario: map['id_usuario'],
      idAuth: map['id_auth'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      correo: map['correo'],
      telefono: map['telefono'],
      estado: map['estado'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_auth': idAuth,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
      'estado': estado,
    };
  }
}
