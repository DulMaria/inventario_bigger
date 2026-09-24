import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';
import '../controller/admin_controller.dart';

class PerfilUsuarioView extends StatefulWidget {
  final bool isEmbedded;
  const PerfilUsuarioView({super.key, this.isEmbedded = false});

  @override
  State<PerfilUsuarioView> createState() => _PerfilUsuarioViewState();
}

class _PerfilUsuarioViewState extends State<PerfilUsuarioView> {
  final AuthController _authController = AuthController();
  final AdminController _adminController = AdminController();

  bool _cargando = true;
  String _nombre = '';
  String _correo = '';
  String _telefono = '';
  String _rol = '';
  int _idUsuario = 0;
  String _idAuth = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic>? usuarioBD;

      if (user != null) {
        _idAuth = user.id;

        // 1. Intentar buscar por id_auth
        try {
          usuarioBD = await Supabase.instance.client
              .from('usuarios')
              .select('*')
              .eq('id_auth', user.id)
              .maybeSingle();
        } catch (e) {
          debugPrint('Error buscando por id_auth: $e');
        }

        // 2. Si no se encontró por id_auth, intentar por correo
        if (usuarioBD == null && user.email != null && user.email!.isNotEmpty) {
          try {
            usuarioBD = await Supabase.instance.client
                .from('usuarios')
                .select('*')
                .eq('correo', user.email!.trim())
                .maybeSingle();
          } catch (e) {
            debugPrint('Error buscando por correo: $e');
          }
        }

        // 3. Si no se encontró, buscar por teléfono en metadata
        if (usuarioBD == null && user.userMetadata?['telefono'] != null) {
          final metaTel = user.userMetadata!['telefono'].toString().trim();
          if (metaTel.isNotEmpty) {
            try {
              usuarioBD = await Supabase.instance.client
                .from('usuarios')
                .select('*')
                .eq('telefono', metaTel)
                .maybeSingle();
            } catch (e) {
              debugPrint('Error buscando por teléfono metadata: $e');
            }
          }
        }
      }

      // 4. Si aún no se encontró, intentar a través de AuthController
      if (usuarioBD == null) {
        try {
          final usuarioModel = await _authController.obtenerUsuarioActual();
          if (usuarioModel != null) {
            usuarioBD = usuarioModel.toMap();
          }
        } catch (_) {}
      }

      String nombreCompleto = '';
      String correo = '';
      String tel = '';
      int idUser = 0;

      if (usuarioBD != null) {
        idUser = usuarioBD['id_usuario'] != null
            ? (usuarioBD['id_usuario'] as num).toInt()
            : 0;
        final nom = (usuarioBD['nombre'] ?? '').toString().trim();
        final ape = (usuarioBD['apellido'] ?? '').toString().trim();
        nombreCompleto = '$nom $ape'.trim();
        correo = (usuarioBD['correo'] ?? '').toString().trim();
        tel = (usuarioBD['telefono'] ?? '').toString().trim();
      }

      // Si falta el nombre, extraerlo de metadatos o correo
      if (nombreCompleto.isEmpty && user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          nombreCompleto =
              '${meta['nombre'] ?? ''} ${meta['apellido'] ?? ''}'.trim();
        }
      }
      if (nombreCompleto.isEmpty && user?.email != null) {
        nombreCompleto = user!.email!.split('@').first;
      }
      if (nombreCompleto.isEmpty) {
        nombreCompleto = 'Usuario';
      }

      if (correo.isEmpty) {
        correo = user?.email ?? '-';
      }

      // Cargar rol del usuario
      String rolStr = 'USUARIO';
      try {
        final r = await _authController.obtenerRolUsuario();
        if (r != null && r.isNotEmpty) {
          rolStr = r.toUpperCase();
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _idUsuario = idUser;
        _nombre = nombreCompleto;
        _correo = correo;
        _telefono = (tel.isNotEmpty && tel != 'null') ? tel : 'Sin registrar';
        _rol = rolStr;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ============================================================
  // DIÁLOGO: CAMBIAR CONTRASEÑA EN SUPABASE AUTH
  // ============================================================
  void _dialogoCambiarPassword() {
    final passNuevaController = TextEditingController();
    final passConfirmController = TextEditingController();
    final formKeyPass = GlobalKey<FormState>();
    bool esOculto = true;
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cambiar Contraseña',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKeyPass,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu nueva contraseña para acceder a la aplicación.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passNuevaController,
                    obscureText: esOculto,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          esOculto ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setModalState(() => esOculto = !esOculto),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la nueva contraseña';
                      }
                      if (value.trim().length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passConfirmController,
                    obscureText: esOculto,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Confirma tu nueva contraseña';
                      }
                      if (value.trim() != passNuevaController.text.trim()) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKeyPass.currentState!.validate()) return;

                      final pass = passNuevaController.text.trim();
                      setModalState(() => guardando = true);

                      try {
                        // 1. Actualizar contraseña en Supabase Auth
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: pass),
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '✅ Contraseña actualizada correctamente en el sistema.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setModalState(() => guardando = false);
                        String errorMsg = e.toString();
                        if (e is AuthException) {
                          errorMsg = e.message;
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al cambiar contraseña: $errorMsg'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIÁLOGO: EDITAR TELÉFONO EN BD (TABLA USUARIOS)
  // ============================================================
  void _dialogoEditarTelefono() {
    final telController = TextEditingController(
      text: _telefono == 'Sin registrar' ? '' : _telefono,
    );
    final formKeyTel = GlobalKey<FormState>();
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.phone_android, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Editar Teléfono',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKeyTel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Actualiza tu número de teléfono en la base de datos.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: telController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Número de Teléfono / WhatsApp',
                    hintText: 'Ej. 77762869',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un número de teléfono';
                    }
                    if (value.trim().length < 6) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKeyTel.currentState!.validate()) return;

                      final newTel = telController.text.trim();
                      setModalState(() => guardando = true);

                      try {
                        final user =
                            Supabase.instance.client.auth.currentUser;

                        final Map<String, dynamic> updateFields = {
                          'telefono': newTel,
                        };
                        if (user != null) {
                          updateFields['id_auth'] = user.id;
                        }
                        if (_correo.contains('@bygger.local')) {
                          updateFields['correo'] = '$newTel@bygger.local';
                        }

                        bool exitoEnBD = false;

                        // 1. Intentar actualizar por id_usuario
                        if (_idUsuario > 0) {
                          try {
                            final res = await Supabase.instance.client
                                .from('usuarios')
                                .update(updateFields)
                                .eq('id_usuario', _idUsuario)
                                .select();
                            if (res.isNotEmpty) {
                              exitoEnBD = true;
                              debugPrint('✅ Teléfono actualizado por id_usuario $_idUsuario');
                            }
                          } catch (e) {
                            debugPrint('Intento por id_usuario falló: $e');
                          }
                        }

                        // 2. Si no se actualizó, intentar por id_auth
                        if (!exitoEnBD && user != null) {
                          try {
                            final res = await Supabase.instance.client
                                .from('usuarios')
                                .update(updateFields)
                                .eq('id_auth', user.id)
                                .select();
                            if (res.isNotEmpty) {
                              exitoEnBD = true;
                              debugPrint('✅ Teléfono actualizado por id_auth ${user.id}');
                            }
                          } catch (e) {
                            debugPrint('Intento por id_auth falló: $e');
                          }
                        }

                        // 3. Si no se actualizó, intentar por correo
                        if (!exitoEnBD && _correo.isNotEmpty && _correo != '-') {
                          try {
                            final res = await Supabase.instance.client
                                .from('usuarios')
                                .update(updateFields)
                                .eq('correo', _correo.trim())
                                .select();
                            if (res.isNotEmpty) {
                              exitoEnBD = true;
                              debugPrint('✅ Teléfono actualizado por correo $_correo');
                            }
                          } catch (e) {
                            debugPrint('Intento por correo falló: $e');
                          }
                        }

                        // 4. Si no se actualizó, intentar por user.email
                        if (!exitoEnBD && user?.email != null && user!.email!.isNotEmpty) {
                          try {
                            final res = await Supabase.instance.client
                                .from('usuarios')
                                .update(updateFields)
                                .eq('correo', user.email!.trim())
                                .select();
                            if (res.isNotEmpty) {
                              exitoEnBD = true;
                              debugPrint('✅ Teléfono actualizado por user.email ${user.email}');
                            }
                          } catch (e) {
                            debugPrint('Intento por user.email falló: $e');
                          }
                        }

                        // 5. Actualizar metadata de Supabase Auth
                        if (user != null) {
                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(data: {'telefono': newTel}),
                            );
                          } catch (_) {}
                        }

                        // 6. Verificar comprobación final en la BD
                        Map<String, dynamic>? checkBD;
                        try {
                          if (_idUsuario > 0) {
                            checkBD = await Supabase.instance.client
                                .from('usuarios')
                                .select('id_usuario, telefono, correo')
                                .eq('id_usuario', _idUsuario)
                                .maybeSingle();
                          } else if (user != null) {
                            checkBD = await Supabase.instance.client
                                .from('usuarios')
                                .select('id_usuario, telefono, correo')
                                .eq('id_auth', user.id)
                                .maybeSingle();
                          }
                        } catch (_) {}

                        if (!mounted) return;

                        if (exitoEnBD || (checkBD != null && checkBD['telefono'] == newTel)) {
                          setState(() {
                            _telefono = newTel;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Teléfono ($newTel) guardado y actualizado en la base de datos.'),
                              backgroundColor: Colors.green.shade800,
                            ),
                          );
                          await _cargarPerfil();
                        } else {
                          // Si RLS bloqueó el UPDATE en Supabase
                          setModalState(() => guardando = false);
                          showDialog(
                            context: context,
                            builder: (alertCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Aviso de Seguridad BD', style: TextStyle(fontSize: 16))),
                                ],
                              ),
                              content: const Text(
                                'La base de datos (Supabase) tiene activas las políticas RLS que impiden modificar la tabla "usuarios" directamente.\n\n'
                                'Para permitir que cualquier usuario edite su propio teléfono, ejecuta este comando en el SQL Editor de Supabase:\n\n'
                                'ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;\n'
                                'o bien:\n'
                                'CREATE POLICY "Permitir update usuarios" ON usuarios FOR UPDATE USING (true);',
                                style: TextStyle(fontSize: 13, height: 1.4),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(alertCtx);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: const Text('Entendido', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => guardando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error al actualizar teléfono: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text(
          '¿Estás seguro de que deseas salir de la aplicación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Sí, Salir'),
          ),
        ],
      ),
    );

    if (res == true) {
      await _authController.cerrarSesion();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Mi Perfil'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              elevation: 0,
            ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _cargarPerfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // CARD ENCABEZADO CON AVATAR
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.surface,
                              child: Text(
                                _nombre.isNotEmpty
                                    ? _nombre[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _nombre,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.surface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ROL: $_rol',
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // INFORMACIÓN PERSONAL
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2A32),
                              ),
                            ),
                            const Divider(height: 20),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              title: const Text(
                                'Correo Electrónico',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                _correo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: Icon(
                                  Icons.phone_outlined,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              title: const Text(
                                'Teléfono / WhatsApp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                _telefono,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 20, color: AppColors.primaryDark),
                                  onPressed: _dialogoEditarTelefono,
                                  tooltip: 'Editar teléfono',
                                ),
                              ),
                            ),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.shade50,
                                child: Icon(
                                  Icons.fingerprint,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              title: const Text(
                                'ID de Usuario',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                _idUsuario > 0 ? '#$_idUsuario' : '#$_idAuth',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CONFIGURACIÓN Y ACCIONES
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.lock_reset,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            title: const Text(
                              'Cambiar Contraseña',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                                const Text('Actualiza tu clave de acceso'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _dialogoCambiarPassword,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade50,
                              child: Icon(
                                Icons.logout,
                                color: Colors.red.shade700,
                              ),
                            ),
                            title: const Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: const Text(
                              'Salir de la cuenta en este dispositivo',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.red,
                            ),
                            onTap: _cerrarSesion,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
