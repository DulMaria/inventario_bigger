import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

old_logic = '''        for (final r in roles) {
        final idRol = r['id_rol'];
        if (idRol == 8) return true;

        final rolData = r['roles'] as Map?;
        final nombreRol = rolData != null 
            ? (rolData['nombre'] as String?)?.toLowerCase() ?? ''
            : '';

        if (nombreRol.contains('admin')) {
          return true;
        }
      }'''

new_logic = '''        for (final r in roles) {
        final idRol = r['id_rol'];
        if (idRol == 8) return true;

        final rolData = r['roles'] as Map?;
        final nombreRol = rolData != null 
            ? ((rolData['nombre_rol'] ?? rolData['nombre']) as String?)?.toLowerCase() ?? ''
            : '';

        if (nombreRol.contains('admin')) {
          return true;
        }
      }'''

content = content.replace(old_logic, new_logic)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
