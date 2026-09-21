# -*- coding: utf-8 -*-
import codecs
import re

file_path = 'lib/modules/administrador/view/perfil_usuario_view.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# Replace _dialogoCambiarPassword
import sys
# It's better to just do string matching carefully
# Let's extract everything between "void _dialogoCambiarPassword() {" and "void _dialogoEditarTelefono() {"

start_pass = "void _dialogoCambiarPassword() {"
end_pass = "void _dialogoEditarTelefono() {"
if start_pass in content and end_pass in content:
    idx1 = content.find(start_pass)
    idx2 = content.find(end_pass)
    
    new_pass = '''void _dialogoCambiarPassword() {
    final passNuevaController = TextEditingController();
    final passConfirmController = TextEditingController();
    final formKeyPass = GlobalKey<FormState>();
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
            child: Form(
              key: formKeyPass,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passNuevaController,
                    obscureText: esOculto,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          esOculto ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setModalState(() => esOculto = !esOculto),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa la contraseña';
                      if (value.length > 8) return 'Máximo 8 caracteres';
                      if (RegExp(r'(.)\\\\1{2,}').hasMatch(value)) return 'No caracteres repetidos 3+ veces';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passConfirmController,
                    obscureText: esOculto,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value != passNuevaController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKeyPass.currentState!.validate()) return;
                
                final pass = passNuevaController.text.trim();
                
                // Llamar al auth controller
                final actualizados =
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
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2FA9E0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  '''
    content = content[:idx1] + new_pass + content[idx2:]


start_tel = "void _dialogoEditarTelefono() {"
end_tel = "void _cerrarSesion() {"
if start_tel in content and end_tel in content:
    idx1 = content.find(start_tel)
    idx2 = content.find(end_tel)

    new_tel = '''void _dialogoEditarTelefono() {
    final telController = TextEditingController();
    final formKeyTel = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
        content: Form(
          key: formKeyTel,
          child: TextFormField(
            controller: telController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nuevo Teléfono',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa el teléfono';
              if (value.trim().length < 7) return 'Debe tener al menos 7 dígitos';
              if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Solo se permiten números';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKeyTel.currentState!.validate()) return;
              
              final tel = telController.text.trim();
              final actualizados = await _authController.actualizarTelefono(tel);
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2FA9E0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  '''
    content = content[:idx1] + new_tel + content[idx2:]

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
print("Updated successfully")
