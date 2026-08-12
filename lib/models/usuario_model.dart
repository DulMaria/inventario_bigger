import 'rol_model.dart';

class UsuarioModel {
  final int idUsuario;
  final String idAuth;
  final RolModel rol;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final bool estado;

  UsuarioModel({
    required this.idUsuario,
    required this.idAuth,
    required this.rol,
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
      rol: RolModel.fromMap(map['roles']),
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
      'id_rol': rol.idRol,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
      'estado': estado,
    };
  }
}