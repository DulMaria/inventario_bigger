import codecs
file_path = 'lib/modules/obra/view/usuarios_por_obra_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = content.replace("telï¿½fono", "teléfono")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
