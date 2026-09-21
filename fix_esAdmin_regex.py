import codecs
import re

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = re.sub(
    r"\? \(rolData\['nombre'\] as String\?\)\?\.toLowerCase\(\) \?\? ''",
    r"? ((rolData['nombre_rol'] ?? rolData['nombre']) as String?)?.toLowerCase() ?? ''",
    content
)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
