import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

import re

# replace all multi-line roles selects
content = re.sub(
    r"\.select\('''(.*?)(roles \((.*?)\))(.*?)'''\)",
    r".select('''\1roles (nombre, nombre_rol)\4''')",
    content,
    flags=re.DOTALL
)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
