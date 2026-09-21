import os

file_path = 'lib/modules/obra/view/gerente_home_view.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(\"nombreObra != null ? 'Obra: \' : 'Bienvenido, Gerente'\", \"nombreObra != null ? '¡Hola! Eres el Gerente de la obra \' : 'Bienvenido, Gerente'\")
content = content.replace(\"'Seleccione una opción para gestionar'\", \"'Desde aquí puedes gestionar los accesos, revisar proformas llegadas y más.'\")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
