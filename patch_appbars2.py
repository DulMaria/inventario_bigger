# -*- coding: utf-8 -*-
import codecs
import re

files_to_patch = [
    'lib/modules/almacen/view/almacen_home_view.dart',
    'lib/modules/tecnico/view/tecnico_home_view.dart',
    'lib/modules/usuario/view/obrero_home_view.dart'
]

for file_path in files_to_patch:
    try:
        with codecs.open(file_path, 'r', 'utf-8') as f:
            content = f.read()

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
      body:'''
        
        # Replace only the first instance of body: in Scaffold
        if 'appBar:' not in content:
            content = re.sub(r'body:\s*', new_appbar, content, count=1)
            with codecs.open(file_path, 'w', 'utf-8') as f:
                f.write(content)
            print(f"Patched {file_path}")
    except Exception as e:
        print(f"Error {file_path}: {e}")
