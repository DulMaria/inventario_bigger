import codecs

file_path = 'lib/core/widgets/custom_drawer.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

start_str = "  @override\n  Widget build(BuildContext context) {"
start_idx = content.find(start_str)

if start_idx != -1:
    new_method = '''  @override
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
'''
    content = content[:start_idx] + new_method
    with codecs.open(file_path, 'w', 'utf-8') as f:
        f.write(content)
