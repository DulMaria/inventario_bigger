# -*- coding: utf-8 -*-
import codecs

file_path = 'lib/modules/administrador/view/perfil_usuario_view.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# Fix password dialog button action
old_pass_btn = '''final actualizados =
                    await _authController.actualizarContrasena(pass);
                if (!mounted) return;
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      actualizados
                          ? 'Contraseña actualizada.'
                          : 'Error al cambiar contraseña.',
                    ),
                  ),
                );'''

new_pass_btn = '''try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: pass),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada correctamente.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cambiar contraseña: \'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }'''

content = content.replace(old_pass_btn, new_pass_btn)

# Fix phone dialog button action
old_tel_btn = '''final actualizados = await _authController.actualizarTelefono(tel);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (actualizados) {
                _cargarPerfil(); // recargar datos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teléfono actualizado.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al cambiar teléfono.')),
                );
              }'''

new_tel_btn = '''try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                   await Supabase.instance.client.from('usuarios').update({'telefono': tel}).eq('id_usuario', user.id);
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                _cargarPerfil();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teléfono actualizado correctamente.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar teléfono: \'),
                    backgroundColor: Colors.red,
                  ),
                );
              }'''

content = content.replace(old_tel_btn, new_tel_btn)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)

print("Updated properly")
