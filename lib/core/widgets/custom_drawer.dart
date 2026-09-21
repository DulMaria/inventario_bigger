import '../../models/usuario_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/auth/view/login_view.dart';
import '../../modules/administrador/view/perfil_usuario_view.dart';

class CustomDrawer extends StatefulWidget {
  final int? selectedIndex;
  final Function(int)? onItemSelected;
  final List<Map<String, dynamic>>? menuItems;

  const CustomDrawer({
    super.key,
    this.selectedIndex,
    this.onItemSelected,
    this.menuItems,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _nombre = 'Cargando...';
  String _rol = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String fetchedNombre = '';
        String fetchedRol = '';

        try {
          final usuarioData = await Supabase.instance.client
              .from('usuarios')
              .select('*')
              .eq('id_auth', user.id)
              .maybeSingle();

          if (usuarioData != null) {
            // Utilizamos el UsuarioModel
            final usuarioModel = UsuarioModel.fromMap(usuarioData);
            fetchedNombre = usuarioModel.nombreCompleto;
            
            final idUsuario = usuarioModel.idUsuario;
            // Buscamos el rol en usuario_obra
            final rolData = await Supabase.instance.client
                .from('usuario_obra')
                .select('roles(nombre, nombre)')
                .eq('id_usuario', idUsuario)
                .eq('estado', true)
                .limit(1)
                .maybeSingle();
                
            if (rolData != null && rolData['roles'] != null) {
              fetchedRol = (rolData['roles']['nombre'] ?? rolData['roles']['nombre'] ?? '').toString().toUpperCase();
            } else {
              // Try in usuario_roles just in case
              final rolData2 = await Supabase.instance.client
                .from('usuario_roles')
                .select('roles(nombre, nombre)')
                .eq('id_usuario', idUsuario)
                .maybeSingle();
              if (rolData2 != null && rolData2['roles'] != null) {
                fetchedRol = (rolData2['roles']['nombre'] ?? rolData2['roles']['nombre'] ?? '').toString().toUpperCase();
              }
            }
          }
        } catch (dbError) {
          debugPrint('Error fetching db user info: $dbError');
        }

        if (fetchedNombre.isEmpty) {
          final meta = user.userMetadata;
          if (meta != null) {
            fetchedNombre = '${meta['nombre'] ?? ''} ${meta['apellido'] ?? ''}'.trim();
          }
        }
        
        if (fetchedNombre.isEmpty && user.email != null) {
          fetchedNombre = user.email!.split('@').first;
        }

        if (fetchedNombre.isEmpty) {
          fetchedNombre = 'Usuario';
        }

        if (mounted) {
          setState(() {
            _nombre = fetchedNombre;
            if (fetchedRol.isNotEmpty) _rol = fetchedRol;
          });
        }
      }
    } catch (e) {
      debugPrint('Error general _cargarDatosUsuario: $e');
      if (mounted) {
        setState(() {
          _nombre = 'Usuario';
        });
      }
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFE1F5FE), // Celeste bebé
      child: Column(
        children: [
          // Header Moderno como el del Admin
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2FA9E0), Color(0xFF2FA9E0)], // Azul medio
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: Color(0xFF2FA9E0),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _nombre.isNotEmpty ? _nombre : 'Usuario',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_rol.isNotEmpty) ...[
                  Text(
                    _rol,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[400]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[400]!),
                  ),
                  child: const Text(
                    '🟢 Acceso Activo',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (widget.menuItems != null && widget.menuItems!.isNotEmpty)
                  ...widget.menuItems!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = widget.selectedIndex == index;
                    
                    return ListTile(
                      leading: Icon(
                        item['icon'],
                        color: isSelected ? const Color(0xFF2FA9E0) : const Color(0xFF1E2A32).withOpacity(0.7),
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF2FA9E0) : const Color(0xFF1E2A32).withOpacity(0.7),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2FA9E0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onItemSelected != null) {
                          widget.onItemSelected!(index);
                        }
                      },
                    );
                  }).toList()
                else
                  ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFF1E2A32)),
                    title: const Text('Mi Perfil', style: TextStyle(color: Color(0xFF1E2A32), fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilUsuarioView()));
                    },
                  ),
                  
                const Divider(),
                
                // Cerrar Sesión
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    _confirmarCerrarSesion(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
