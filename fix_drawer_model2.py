# -*- coding: utf-8 -*-
import codecs
import re

drawer_path = 'lib/core/widgets/custom_drawer.dart'

with codecs.open(drawer_path, 'r', 'utf-8') as f:
    content = f.read()

start_str = "Future<void> _cargarDatosUsuario() async {"
end_str = "void _cerrarSesion()"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_method = '''Future<void> _cargarDatosUsuario() async {
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
                .select('roles(nombre_rol)')
                .eq('id_usuario', idUsuario)
                .eq('estado', true)
                .maybeSingle();
                
            // Como puede que el rol este en usuario_roles o usuario_obra dependiendo de la db
            if (rolData != null && rolData['roles'] != null) {
              fetchedRol = (rolData['roles']['nombre_rol'] ?? rolData['roles']['nombre'] ?? '').toString().toUpperCase();
            } else {
              // Try in usuario_roles just in case
              final rolData2 = await Supabase.instance.client
                .from('usuario_roles')
                .select('roles(nombre_rol)')
                .eq('id_usuario', idUsuario)
                .maybeSingle();
              if (rolData2 != null && rolData2['roles'] != null) {
                fetchedRol = (rolData2['roles']['nombre_rol'] ?? '').toString().toUpperCase();
              }
            }
          }
        } catch (dbError) {
          debugPrint('Error fetching db user info: \');
        }

        if (fetchedNombre.isEmpty) {
          final meta = user.userMetadata;
          if (meta != null) {
            fetchedNombre = "\ \".trim();
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
      debugPrint('Error general _cargarDatosUsuario: \');
    }
  }

  '''
    content = content[:start_idx] + new_method + content[end_idx:]
    
    # ensure import
    if 'import \'../../models/usuario_model.dart\';' not in content and 'import \'package:inventario_bigger/models/usuario_model.dart\';' not in content:
        content = "import '../../models/usuario_model.dart';\n" + content
        
    with codecs.open(drawer_path, 'w', 'utf-8') as f:
        f.write(content)
    print("Drawer replaced method")
