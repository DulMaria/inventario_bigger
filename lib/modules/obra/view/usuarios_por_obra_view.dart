import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/obra_model.dart';
import '../../../modules/administrador/service/admin_service.dart';
import '../../../core/config/app_colors.dart';

class UsuariosPorObraView extends StatefulWidget {
  final ObraModel obra;
  final bool isEmbedded;

  const UsuariosPorObraView({super.key, required this.obra, this.isEmbedded = false});

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


  String _searchQuery = '';

  Future<void> _cambiarEstadoObra(int idUsuario, bool estadoActual) async {
    final nuevoEstado = !estadoActual;
    final accion = nuevoEstado ? 'habilitar' : 'inhabilitar';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(nuevoEstado ? 'Habilitar en Obra' : 'Inhabilitar en Obra'),
        content: Text('¿Estás seguro de que deseas $accion a este usuario en la obra?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: nuevoEstado ? Colors.green : Colors.red, foregroundColor: AppColors.surface),
            child: Text(nuevoEstado ? 'Sí, Habilitar' : 'Sí, Inhabilitar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('usuario_obra').update({'estado': nuevoEstado}).eq('id_usuario', idUsuario).eq('id_obra', widget.obra.idObra);
        _cargarUsuarios();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final adminService = AdminService();
      final todosLosUsuarios = await adminService.getUsuarios();
      
      final List<Map<String, dynamic>> list = [];
      
      for (var uData in todosLosUsuarios) {
        final obrasDetalladas = uData['obras_detalladas'] as List<dynamic>? ?? [];
        
        // Buscar si este usuario está en la obra actual
        var obraAsignada;
        for (var od in obrasDetalladas) {
          if (od['id_obra'] == widget.obra.idObra) {
            obraAsignada = od;
            break;
          }
        }
        
        final bool esAdmin = uData['rol']?.toString().toLowerCase().contains('admin') == true;
        
        if (obraAsignada != null || esAdmin) {
          list.add({
            'id_usuario': uData['id_usuario'],
            'nombre_completo': '${uData['nombre'] ?? ''} ${uData['apellido'] ?? ''}'.trim(),
            'correo': uData['correo'] ?? 'Sin correo',
            'telefono': uData['telefono'] ?? 'Sin teléfono',
            'rol': (obraAsignada != null && obraAsignada['nombre_rol'] != null) 
                   ? obraAsignada['nombre_rol'] 
                   : (uData['rol'] ?? 'Administrador'),
            'estado_global': uData['estado'] == true,
            'estado_en_obra': (obraAsignada != null && obraAsignada['estado'] != null) 
                              ? (obraAsignada['estado'] == true) 
                              : true,
          });
        }
      }

      setState(() {
        _usuarios = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
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
    final listaFiltrada = _searchQuery.isEmpty ? _usuarios : _usuarios.where((u) {
      final text = '${u['nombre_completo']} ${u['correo']}'.toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar usuario...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : listaFiltrada.isEmpty
                  ? const Center(child: Text('No hay usuarios'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final u = listaFiltrada[index];
                        final bool activoObra = u['estado_en_obra'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u['nombre_completo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(u['rol'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(u['correo'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.circle, size: 10, color: activoObra ? Colors.green : Colors.red),
                                        const SizedBox(width: 4),
                                        Text(activoObra ? 'Activo' : 'Inactivo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: activoObra ? Colors.red.shade50 : Colors.green.shade50,
                                        foregroundColor: activoObra ? Colors.red.shade700 : Colors.green.shade700,
                                        elevation: 0,
                                        side: BorderSide(color: activoObra ? Colors.red.shade200 : Colors.green.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        minimumSize: const Size(0, 26),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(activoObra ? Icons.block : Icons.check_circle_outline, size: 12),
                                      label: Text(activoObra ? 'Inhabilitar' : 'Habilitar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _cambiarEstadoObra(u['id_usuario'], activoObra),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Usuarios - ${widget.obra.nombre}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: body,
    );
  }
}
