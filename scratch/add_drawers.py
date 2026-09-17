import os
import re

files = [
    'lib/modules/usuario/view/obrero_home_view.dart',
    'lib/modules/obra/view/gerente_home_view.dart',
    'lib/modules/tecnico/view/tecnico_home_view.dart',
    'lib/modules/compras/view/compras_home_view.dart',
    'lib/modules/almacen/view/almacen_home_view.dart'
]

drawer_code = '''
      drawer: Drawer(
        backgroundColor: const Color(0xFFE1F5FE),
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6FC6EE)),
              accountName: Text('Panel de Usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2A32))),
              accountEmail: Text('Opciones', style: TextStyle(color: Color(0xFF1E2A32))),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF2FA9E0), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1E2A32)),
              title: const Text('Mi Perfil', style: TextStyle(color: Color(0xFF1E2A32), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilUsuarioView()));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
'''

for file_path in files:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add import
    if 'PerfilUsuarioView' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../administrador/view/perfil_usuario_view.dart';")
    
    # Add drawer if not exists
    if 'drawer: Drawer' not in content:
        content = re.sub(r'(Scaffold\(\s*backgroundColor:[^,]+,)', r'\1' + drawer_code, content)
        if 'drawer: Drawer' not in content:
            content = re.sub(r'(Scaffold\(\s*appBar:)', drawer_code.lstrip() + r'\n      appBar:', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print('Updated files with drawers.')
