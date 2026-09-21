# -*- coding: utf-8 -*-
import codecs

files_to_patch = [
    'lib/modules/almacen/view/almacen_home_view.dart',
    'lib/modules/tecnico/view/tecnico_home_view.dart',
    'lib/modules/usuario/view/obrero_home_view.dart'
]

for file_path in files_to_patch:
    with codecs.open(file_path, 'r', 'utf-8') as f:
        content = f.read()

    # We want to change the AppBar backgroundColor
    # from Color(0xFF1B2A47) to Color(0xFF2FA9E0)
    # But ONLY in the AppBar
    # So let's just do a simple replacement if it's near AppBar
    
    # Just replace all Color(0xFF1B2A47) with Color(0xFF2FA9E0) inside these views because 0xFF1B2A47 is the dark blue, and user wants the light baby blue!
    # Wait, 1B2A47 is used for active tabs or icons too. The user said:
    # "ajuta sus vistas a los colores y que sea moderno y asi y que tenga accesibilidad"
    # Replacing all might make things unreadable if white text is on light blue, but 0xFF2FA9E0 with white text is perfectly readable!
    
    # Let's replace ONLY backgroundColor: const Color(0xFF1B2A47) in the AppBar.
    # We can do this by regex or string replace.
    
    old_appbar = '''backgroundColor: const Color(0xFF1B2A47),
        foregroundColor: Colors.white,'''
    new_appbar = '''backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,'''
        
    content = content.replace(old_appbar, new_appbar)
    
    with codecs.open(file_path, 'w', 'utf-8') as f:
        f.write(content)
        
print("Colors updated")
