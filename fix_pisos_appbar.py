import codecs
import re

file_path = 'lib/modules/piso/view/pisos_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

pattern = re.compile(r"appBar:\s*AppBar\(\s*title:\s*Text\('Pisos -\s*\$\{\s*widget\.obra\.nombre\s*\}'\),\s*backgroundColor:\s*const\s*Color\(0xFF2FA9E0\),\s*foregroundColor:\s*Colors\.white,\s*centerTitle:\s*true,\s*\)", re.DOTALL)

new_appbar = '''appBar: AppBar(
        title: Text('Pisos - \'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Ver Usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UsuariosPorObraView(obra: widget.obra),
                ),
              );
            },
          ),
        ],
      )'''

if pattern.search(content):
    content = pattern.sub(new_appbar, content)
else:
    print("Pattern not found!")

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
