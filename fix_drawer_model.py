# -*- coding: utf-8 -*-
import codecs

drawer_path = 'lib/core/widgets/custom_drawer.dart'

with codecs.open(drawer_path, 'r', 'utf-8') as f:
    content = f.read()

# We need to replace everything inside _cargarDatos()
import re

start_str = "Future<void> _cargarDatos() async {"
end_str = "void _cerrarSesion()"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_method = '''Future<void> _cargarDatos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final usuarioModel = await _authController.obtenerUsuarioActual();
        final rol = await _authController.obtenerRolUsuario();

        if (mounted) {
          setState(() {
            _rol = rol ?? 'Usuario';
            
            if (usuarioModel != null) {
                _nombre = usuarioModel.nombreCompleto;
            } else if (user.userMetadata != null && user.userMetadata!['nombre'] != null) {
                _nombre = "\\ \\".trim();
            } else if (user.email != null) {
                _nombre = user.email!.split('@').first;
            } else {
                _nombre = 'Usuario';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario en Drawer: \');
    }
  }

  '''
    content = content[:start_idx] + new_method + content[end_idx:]
    with codecs.open(drawer_path, 'w', 'utf-8') as f:
        f.write(content)
    print("Drawer replaced method")
