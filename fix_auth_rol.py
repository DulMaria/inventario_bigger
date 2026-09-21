import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = content.replace("roles (\n                nombre\n              )", "roles (nombre, nombre_rol)")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
