import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = content.replace("return rolData['nombre'] as String?;", "return (rolData['nombre_rol'] ?? rolData['nombre']) as String?;")
content = content.replace("nombreRol = rolData['nombre'] as String?;", "nombreRol = (rolData['nombre_rol'] ?? rolData['nombre']) as String?;")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
