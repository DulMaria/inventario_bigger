import codecs
import re

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = content.replace("roles (nombre, nombre_rol)", "roles (nombre)")
content = content.replace("(rolData['nombre_rol'] ?? rolData['nombre']) as String?", "rolData['nombre'] as String?")
content = content.replace("((rolData['nombre_rol'] ?? rolData['nombre']) as String?)", "(rolData['nombre'] as String?)")


with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)

file_path2 = 'lib/core/widgets/custom_drawer.dart'
with codecs.open(file_path2, 'r', 'utf-8') as f2:
    content2 = f2.read()
    
content2 = content2.replace("roles (nombre, nombre_rol)", "roles (nombre)")
content2 = content2.replace("(rolData['nombre_rol'] ?? rolData['nombre']) as String?", "rolData['nombre'] as String?")

with codecs.open(file_path2, 'w', 'utf-8') as f2:
    f2.write(content2)

