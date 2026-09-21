# -*- coding: utf-8 -*-
import codecs

file_path = 'lib/modules/administrador/view/perfil_usuario_view.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# We need to reconstruct initState and _cargarPerfil

start_str = "void initState() {"
end_str = "void _dialogoCambiarPassword() {"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_method = '''void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      final userActualId = await _authController.obtenerIdUsuario();
      final usuarioModel = await _authController.obtenerUsuarioActual();
      final rol = await _authController.obtenerRolUsuario();

      String nombreCompleto = '';
      if (usuarioModel != null) {
        nombreCompleto = usuarioModel.nombreCompleto;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (nombreCompleto.isEmpty && user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          nombreCompleto = "\ \".trim();
        }
      }
      if (nombreCompleto.isEmpty && user != null && user.email != null) {
        nombreCompleto = user.email!.split('@').first;
      }
      if (nombreCompleto.isEmpty) {
        nombreCompleto = 'Usuario';
      }

      final correo = usuarioModel?.correo ?? '-';
      final tel = usuarioModel?.telefono ?? '-';

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

  '''
    content = content[:start_idx] + new_method + content[end_idx:]
    with codecs.open(file_path, 'w', 'utf-8') as f:
        f.write(content)
    print("Fixed Perfil")
