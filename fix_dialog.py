# -*- coding: utf-8 -*-
import codecs
import re

file_path = 'lib/modules/administrador/view/perfil_usuario_view.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# I will use regex to find the bodies
old_dialog_pass = '''TextField(
                    controller: passNuevaController,
                    obscureText: esOculto,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),'''

if old_dialog_pass in content:
    print("Found pass")
    # Will do it carefully later
