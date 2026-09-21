import codecs
file_path = 'lib/modules/administrador/view/admin_page.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

content = content.replace("return const SolicitudesAccesoView();", "return const SolicitudesAccesoView(isEmbedded: true);")
content = content.replace("return const PerfilUsuarioView();", "return const PerfilUsuarioView(isEmbedded: true);")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
