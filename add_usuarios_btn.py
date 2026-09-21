import codecs
file_path = 'lib/modules/piso/view/pisos_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

import_statement = "import '../../obra/view/usuarios_por_obra_view.dart';\n"
if import_statement not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)

appbar_code = '''      appBar: AppBar(
        title: Text('Pisos - \'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Ver Usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UsuariosPorObraView(obra: widget.obra),
                ),
              );
            },
          ),
        ],
      ),'''

content = content.replace('''      appBar: AppBar(
        title: Text('Pisos - \'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),''', appbar_code)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
