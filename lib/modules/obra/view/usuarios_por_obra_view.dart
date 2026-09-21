import 'package:flutter/material.dart';
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
                            Text(u['correo']),
                            Text(u['telefono']),
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
