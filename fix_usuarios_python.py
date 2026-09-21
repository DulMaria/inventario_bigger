
import codecs
import re

file_path = 'lib/modules/obra/view/usuarios_por_obra_view.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

new_logic = '''  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Obtener todas las relaciones de usuario_obra para esta obra
      final uoRes = await supabase
          .from('usuario_obra')
          .select('*')
          .eq('id_obra', widget.obra.idObra);
          
      // 2. Obtener todos los usuarios y mapearlos
      final usrRes = await supabase.from('usuarios').select('*');
      final Map<int, Map<String, dynamic>> usuariosMap = {};
      for (var u in (usrRes as List)) {
        usuariosMap[u['id_usuario']] = u;
      }
      
      // 3. Obtener todos los roles y mapearlos
      final rolRes = await supabase.from('roles').select('*');
      final Map<int, String> rolesMap = {};
      for (var r in (rolRes as List)) {
        rolesMap[r['id_rol']] = r['nombre'];
      }

      final List<Map<String, dynamic>> list = [];
      for (var item in (uoRes as List)) {
        final idUsuario = item['id_usuario'];
        final idRol = item['id_rol'];
        
        final uData = usuariosMap[idUsuario];
        if (uData != null) {
          list.add({
            'nombre_completo': ' '.trim(),
            'correo': uData['correo'] ?? 'Sin correo',
            'telefono': uData['telefono'] ?? 'Sin teléfono',
            'rol': rolesMap[idRol] ?? 'Desconocido',
            'estado_global': uData['estado'] == true,
            'estado_en_obra': item['estado'] == true,
          });
        }
      }

      setState(() {
        _usuarios = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }'''

# Replace the old _cargarUsuarios method
pattern = re.compile(r'Future<void>\s+_cargarUsuarios\(\)\s*async\s*\{.*?\n  \}', re.DOTALL)
content = pattern.sub(new_logic, content)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)

