import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# Let's just find and replace the whole function using regex
import re

content = re.sub(
    r"Future<String\?> obtenerRolUsuario\(\).*?return null;\s*\}\s*catch\s*\(e\)\s*\{\s*print\('Error al obtener rol: \'\);\s*return null;\s*\}",
    r'''Future<String?> obtenerRolUsuario() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return null;
    try {
      final usuarioBD = await _supabase.from('usuarios').select('id_usuario').eq('id_auth', usuario.id).maybeSingle();
      if (usuarioBD == null) return null;
      final idUsuario = usuarioBD['id_usuario'] as int;
      
      final rol = await _supabase.from('usuario_obra').select('roles(nombre, nombre_rol)').eq('id_usuario', idUsuario).eq('estado', true).maybeSingle();
      if (rol != null && rol['roles'] != null) {
        final rolData = rol['roles'] as Map;
        return (rolData['nombre_rol'] ?? rolData['nombre'])?.toString();
      }
      
      final rol2 = await _supabase.from('usuario_roles').select('roles(nombre, nombre_rol)').eq('id_usuario', idUsuario).maybeSingle();
      if (rol2 != null && rol2['roles'] != null) {
        final rolData = rol2['roles'] as Map;
        return (rolData['nombre_rol'] ?? rolData['nombre'])?.toString();
      }
      
      return null;
    } catch (e) {
      print('Error al obtener rol: ');
      return null;
    }
  }''',
    content,
    flags=re.DOTALL
)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
