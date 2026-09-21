# -*- coding: utf-8 -*-
import codecs

auth_service_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(auth_service_path, 'r', 'utf-8') as f:
    content = f.read()

new_method = '''
  Future<UsuarioModel?> obtenerUsuarioActual() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return null;
    try {
      final data = await _supabase
          .from('usuarios')
          .select('*')
          .eq('id_auth', usuario.id)
          .maybeSingle();
      if (data != null) {
        return UsuarioModel.fromMap(data);
      }
    } catch (e) {
      print('Error al obtener UsuarioModel: \');
    }
    return null;
  }
'''

if 'obtenerUsuarioActual' not in content:
    # insert before the last closing brace or after obtenerDatosUsuario
    idx = content.find('Future<Map<String, dynamic>?')
    if idx != -1:
        content = content[:idx] + new_method + content[idx:]
        # need to import UsuarioModel
        if 'import \'../../../models/usuario_model.dart\';' not in content:
            content = "import '../../../models/usuario_model.dart';\n" + content
        with codecs.open(auth_service_path, 'w', 'utf-8') as f:
            f.write(content)

auth_controller_path = 'lib/modules/auth/controller/auth_controller.dart'
with codecs.open(auth_controller_path, 'r', 'utf-8') as f:
    content = f.read()

new_ctrl_method = '''
  Future<UsuarioModel?> obtenerUsuarioActual() async {
    return await _authService.obtenerUsuarioActual();
  }
'''
if 'obtenerUsuarioActual' not in content:
    idx = content.find('Future<Map<String, dynamic>?')
    if idx != -1:
        content = content[:idx] + new_ctrl_method + content[idx:]
        if 'import \'../../../models/usuario_model.dart\';' not in content:
            content = "import '../../../models/usuario_model.dart';\n" + content
        with codecs.open(auth_controller_path, 'w', 'utf-8') as f:
            f.write(content)

# Now update CustomDrawer and PerfilUsuarioView to use UsuarioModel
print("Added method")
