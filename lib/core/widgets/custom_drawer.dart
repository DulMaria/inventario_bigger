import '../../models/usuario_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/auth/view/login_view.dart';
import '../../modules/administrador/view/perfil_usuario_view.dart';
import '../config/app_colors.dart';

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
  // Cache estático: sobrevive aunque el Drawer se destruya y se vuelva
  // a crear cada vez que se abre. Así evitamos el flash de "Usuario".
  static String? _cachedNombre;
  static String? _cachedRol;

  String _nombre = '';
  String _rol = '';

  @override
  void initState() {
    super.initState();
    // 1) Mostramos de inmediato lo que ya teníamos en caché (si existe).
    _nombre = _cachedNombre ?? '';
    _rol = _cachedRol ?? '';
    // 2) Refrescamos en segundo plano (sin "parpadeo" si el dato no cambió).
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
            final usuarioModel = UsuarioModel.fromMap(usuarioData);
            fetchedNombre = usuarioModel.nombreCompleto;

            final idUsuario = usuarioModel.idUsuario;
            final rolData = await Supabase.instance.client
                .from('usuario_obra')
                .select('roles(nombre, nombre)')
                .eq('id_usuario', idUsuario)
                .eq('estado', true)
                .limit(1)
                .maybeSingle();

            if (rolData != null && rolData['roles'] != null) {
              fetchedRol = (rolData['roles']['nombre'] ?? '').toString().toUpperCase();
            } else {
              final rolData2 = await Supabase.instance.client
                  .from('usuario_roles')
                  .select('roles(nombre, nombre)')
                  .eq('id_usuario', idUsuario)
                  .maybeSingle();
              if (rolData2 != null && rolData2['roles'] != null) {
                fetchedRol = (rolData2['roles']['nombre'] ?? '').toString().toUpperCase();
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

        // Actualizamos la caché estática para la próxima apertura del drawer.
        _cachedNombre = fetchedNombre;
        if (fetchedRol.isNotEmpty) _cachedRol = fetchedRol;

        if (mounted) {
          // Solo hacemos setState si realmente cambió algo,
          // para no repintar innecesariamente.
          final nuevoRol = fetchedRol.isNotEmpty ? fetchedRol : _rol;
          if (_nombre != fetchedNombre || _rol != nuevoRol) {
            setState(() {
              _nombre = fetchedNombre;
              _rol = nuevoRol;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error general _cargarDatosUsuario: $e');
      if (mounted && _nombre.isEmpty) {
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

    if (confirmar == true) {
      // Limpiamos la caché de usuario al cerrar sesión.
      _cachedNombre = null;
      _cachedRol = null;

      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Error al cerrar sesión: $e');
      }

      if (!context.mounted) return;

      // Usamos rootNavigator para asegurarnos de salir de cualquier
      // contexto anidado (drawer, diálogos, etc.) sin problemas.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 16,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary],
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
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _nombre.isNotEmpty ? _nombre : ' ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_rol.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _rol,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  if (widget.menuItems != null && widget.menuItems!.isNotEmpty)
                    ...widget.menuItems!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = widget.selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(context);
                            if (widget.onItemSelected != null) {
                              widget.onItemSelected!(index);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: Icon(
                                item['icon'],
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              title: Text(
                                item['title'],
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: const Icon(Icons.person, color: AppColors.textSecondary),
                        title: const Text('Mi Perfil', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilUsuarioView()));
                        },
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(color: AppColors.backgroundLight),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onTap: () {
                        // Ya NO cerramos el drawer aquí. Primero confirmamos.
                        _confirmarCerrarSesion(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}