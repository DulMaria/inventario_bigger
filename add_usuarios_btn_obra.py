import codecs
file_path = 'lib/modules/obra/view/obra_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

import_statement = "import 'usuarios_por_obra_view.dart';\n"
if import_statement not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)

old_trailing = '''                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                            ),
                            onPressed: () {
                              _irAEditarObra(obra);
                            },
                          ),'''

new_trailing = '''                          trailing: Row(
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
                          ),'''

content = content.replace(old_trailing, new_trailing)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
