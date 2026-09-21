import codecs

content = '''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/obra_model.dart';

class UsuariosPorObraView extends StatefulWidget {
  final ObraModel obra;

  const UsuariosPorObraView({super.key, required this.obra});

  @override
  State<UsuariosPorObraView> createState() => _UsuariosPorObraViewState();
}

class _UsuariosPorObraViewState extends State<UsuariosPorObraView> {
  bool _cargando = true;
  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('usuario_obra')
          .select("""
            id_usuario_obra,
            estado,
            roles (nombre),
            usuarios (
              id_usuario,
              nombre,
              apellido,
              correo,
              telefono,
              estado
            )
          """)
          .eq('id_obra', widget.obra.idObra);

      final List<Map<String, dynamic>> list = [];
      for (var item in response) {
        final rolData = item['roles'] as Map?;
        final usuarioData = item['usuarios'] as Map?;
        if (usuarioData != null) {
          list.add({
            'nombre_completo': ' '.trim(),
            'correo': usuarioData['correo'] ?? 'Sin correo',
            'telefono': usuarioData['telefono'] ?? 'Sin teléfono',
            'rol': rolData?['nombre'] ?? 'Desconocido',
            'estado_global': usuarioData['estado'] == true,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: Text('Usuarios - '),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? const Center(child: Text('No hay usuarios en esta obra'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final u = _usuarios[index];
                    final bool activoObra = u['estado_en_obra'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2FA9E0).withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: Color(0xFF2FA9E0)),
                        ),
                        title: Text(
                          u['nombre_completo'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['rol'], style: const TextStyle(color: Color(0xFF2FA9E0), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(''),
                            Text(''),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: activoObra ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activoObra ? 'Activo en Obra' : 'Inactivo en Obra',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
'''

with codecs.open('lib/modules/obra/view/usuarios_por_obra_view.dart', 'w', 'utf-8') as f:
    f.write(content.replace("\\$", "$"))
