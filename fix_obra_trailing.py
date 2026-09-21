import codecs
import re

file_path = 'lib/modules/obra/view/obra_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

import_statement = "import 'usuarios_por_obra_view.dart';"
if import_statement not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)

# Regex to find trailing IconButton with Icons.edit
pattern = re.compile(r"trailing:\s*IconButton\(\s*icon:\s*const\s*Icon\(\s*Icons\.edit,\s*\),\s*onPressed:\s*\(\)\s*\{\s*_irAEditarObra\(obra\);\s*},\s*\)", re.DOTALL)

new_trailing = '''trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.people, color: Color(0xFF2FA9E0)),
                                tooltip: 'Ver Usuarios',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UsuariosPorObraView(obra: obra),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar Obra',
                                onPressed: () {
                                  _irAEditarObra(obra);
                                },
                              ),
                            ],
                          )'''

if pattern.search(content):
    content = pattern.sub(new_trailing, content)
else:
    print("Pattern not found!")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
