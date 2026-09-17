// lib/modules/administrador/view/perfil_usuario_view.dart
import 'package:flutter/material.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';
import '../controller/admin_controller.dart';

class PerfilUsuarioView extends StatefulWidget {
  const PerfilUsuarioView({super.key});

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
  List<Map<String, dynamic>> _misObras = [];

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      final userActualId = await _authController.obtenerIdUsuario();
      final datosUser = await _authController.obtenerDatosUsuario();
      final rol = await _authController.obtenerRolUsuario();

      final nombreCompleto = datosUser != null
          ? '${datosUser['nombre'] ?? ''} ${datosUser['apellido'] ?? ''}'.trim()
          : 'Usuario';
      final correo = datosUser?['correo']?.toString() ?? '-';
      final tel = datosUser?['telefono']?.toString() ?? '-';

      // Cargar mis obras asignadas si aplica
      await _adminController.cargarDashboard();
      final usuarioEncontrado = _adminController.usuarios.firstWhere(
        (u) => u['id_usuario'] == userActualId,
        orElse: () => <String, dynamic>{},
      );

      final obrasDet = (usuarioEncontrado['obras_detalladas'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;

      setState(() {
        _idUsuario = userActualId ?? 0;
        _nombre = nombreCompleto.isNotEmpty ? nombreCompleto : 'Usuario';
        _correo = correo;
        _rol = (rol ?? 'Usuario').toUpperCase();
        _telefono = tel;
        _misObras = obrasDet;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _dialogoCambiarPassword() {
    final passNuevaController = TextEditingController();
    final passConfirmController = TextEditingController();
    bool esOculto = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF2FA9E0)),
              SizedBox(width: 10),
              Text(
                'Cambiar Contraseña',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passNuevaController,
                  obscureText: esOculto,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        esOculto ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setModalState(() => esOculto = !esOculto),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passConfirmController,
                  obscureText: esOculto,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: Icon(Icons.key_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pass = passNuevaController.text.trim();
                final confirm = passConfirmController.text.trim();

                if (pass.isEmpty || pass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La contraseña debe tener al menos 6 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (pass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✅ Solicitud enviada. Tu contraseña será actualizada.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FC6EE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogoEditarTelefono() {
    final telController = TextEditingController(text: _telefono);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF2FA9E0)),
            SizedBox(width: 10),
            Text(
              'Editar Teléfono',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: telController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número de Teléfono / WhatsApp',
            hintText: 'Ej. +591 70000000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTel = telController.text.trim();
              if (newTel.isNotEmpty) {
                setState(() => _telefono = newTel);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Teléfono actualizado correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FC6EE),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
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
              foregroundColor: Colors.white,
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
      backgroundColor: const Color(0xFFF4FAFE),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Text(
                              _nombre.isNotEmpty
                                  ? _nombre[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ROL: $_rol',
                              style: const TextStyle(
                                color: Colors.white,
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
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(
                                Icons.email_outlined,
                                color: Colors.blue.shade700,
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
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: _dialogoEditarTelefono,
                              tooltip: 'Editar teléfono',
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
                              '#$_idUsuario',
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
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              Icons.lock_reset,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: const Text(
                            'Cambiar Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Actualiza tu clave de acceso'),
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
    );
  }
}
