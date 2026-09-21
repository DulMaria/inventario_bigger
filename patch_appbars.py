# -*- coding: utf-8 -*-
import codecs
import re

files_to_patch = [
    'lib/modules/compras/view/compras_home_view.dart',
    'lib/modules/almacen/view/almacen_home_view.dart',
    'lib/modules/tecnico/view/tecnico_home_view.dart',
    'lib/modules/usuario/view/obrero_home_view.dart'
]

for file_path in files_to_patch:
    try:
        with codecs.open(file_path, 'r', 'utf-8') as f:
            content = f.read()

        # Find Scaffold(
        scaffold_idx = content.find('return Scaffold(')
        if scaffold_idx == -1:
            print(f"Skipped {file_path}")
            continue
            
        # Check if already has appBar
        body_idx = content.find('body:', scaffold_idx)
        if 'appBar:' not in content[scaffold_idx:body_idx]:
            # Insert appBar
            new_appbar = '''appBar: AppBar(
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        title: Text(widget.nombreObra ?? 'Panel'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SeleccionarObraView()),
                (route) => false,
              );
            },
            tooltip: 'Cambiar Obra',
          ),
        ],
      ),
      '''
            content = content[:body_idx] + new_appbar + content[body_idx:]
            
            with codecs.open(file_path, 'w', 'utf-8') as f:
                f.write(content)
            print(f"Patched {file_path}")
    except Exception as e:
        print(f"Error {file_path}: {e}")
