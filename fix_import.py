import codecs

drawer_path = 'lib/core/widgets/custom_drawer.dart'

with codecs.open(drawer_path, 'r', 'utf-8') as f:
    content = f.read()

import_statement = "import '../../models/usuario_model.dart';\n"

if 'usuario_model.dart' not in content:
    # find the first import and insert it there
    idx = content.find('import')
    if idx != -1:
        content = content[:idx] + import_statement + content[idx:]
    else:
        content = import_statement + content
        
    with codecs.open(drawer_path, 'w', 'utf-8') as f:
        f.write(content)
