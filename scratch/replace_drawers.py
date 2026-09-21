# -*- coding: utf-8 -*-
import os
import re

files = [
    'lib/modules/solicitud_acceso/view/seleccionar_obra_view.dart',
    'lib/modules/obra/view/gerente_home_view.dart',
    'lib/modules/usuario/view/obrero_home_view.dart',
    'lib/modules/tecnico/view/tecnico_home_view.dart',
    'lib/modules/compras/view/compras_home_view.dart',
    'lib/modules/almacen/view/almacen_home_view.dart'
]

for file_path in files:
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Calculate import path
    depth = file_path.count('/') - 1
    import_path = '../' * depth + 'core/widgets/custom_drawer.dart'
    
    if 'CustomDrawer' not in content:
        content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\nimport '{import_path}';")
        
    # Regex to match the old drawer
    # The old drawer looks like: drawer: Drawer( ... ), up to the next attribute or widget end.
    # It's safer to use regex to find drawer: Drawer( ... ) and replace it entirely.
    
    # Find the start of drawer: Drawer(
    start_idx = content.find('drawer: Drawer(')
    if start_idx != -1:
        # We need to find the matching closing brace.
        brace_count = 0
        end_idx = -1
        for i in range(start_idx + 14, len(content)):
            if content[i] == '(':
                brace_count += 1
            elif content[i] == ')':
                brace_count -= 1
                if brace_count == 0:
                    end_idx = i
                    break
                    
        if end_idx != -1:
            old_drawer = content[start_idx:end_idx+1]
            content = content.replace(old_drawer, 'drawer: const CustomDrawer()')
            
    # Remove leading: IconButton(...) from AppBar if it exists, so the drawer can show up!
    # Specifically looking for:
    # leading: IconButton(
    #   icon: const Icon(Icons.arrow_back),
    #   onPressed: ...
    # ),
    # Actually, it's safer to just remove leading: IconButton( block.
    
    start_idx = content.find('leading: IconButton(')
    if start_idx != -1:
        brace_count = 0
        end_idx = -1
        for i in range(start_idx + 19, len(content)):
            if content[i] == '(':
                brace_count += 1
            elif content[i] == ')':
                brace_count -= 1
                if brace_count == 0:
                    end_idx = i
                    break
        if end_idx != -1:
            # check if the next char is a comma and remove it
            if end_idx + 1 < len(content) and content[end_idx+1] == ',':
                end_idx += 1
            old_leading = content[start_idx:end_idx+1]
            content = content.replace(old_leading, '')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print('Updated files with CustomDrawer and removed back button if present.')
