// lib/modules/administrador/view/admin_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/admin_controller.dart';

// ✅ IMPORTAR VISTAS EXISTENTES
import '../../obra/view/obra_view.dart';
import '../../piso/view/pisos_view.dart';
import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';  // ✅ NUEVA IMPORTACIÓN
import '../../../models/obra_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());

    return Scaffold(
      drawer: _buildDrawer(context, controller),
      appBar: AppBar(
        title: Obx(() {
          final titles = [
            'Dashboard',
            'Obras',
            'Pisos',
            'Usuarios',
            'Solicitudes',
          ];
          return Text(titles[controller.selectedIndex.value]);
        }),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshDashboard,
            tooltip: 'Refrescar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando datos...'),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshDashboard,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return _buildBody(context, controller);
      }),
    );
  }

  // ============================================================
  // DRAWER - MENÚ LATERAL CON PERFIL
  // ============================================================
  Widget _buildDrawer(BuildContext context, AdminController controller) {
    return Drawer(
      child: Column(
        children: [
          // Header - Perfil del Administrador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[900]!],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() => Text(
                  controller.adminNombre.value.isNotEmpty
                      ? controller.adminNombre.value
                      : 'Administrador',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                Obx(() => Text(
                  controller.adminRol.value.isNotEmpty
                      ? controller.adminRol.value
                      : 'Administrador',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                )),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.adminTelefono.value.isEmpty) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📱 ${controller.adminTelefono.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Obx(() {
                  if (controller.adminCorreo.value.isEmpty) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '✉️ ${controller.adminCorreo.value}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[400]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[400]!),
                  ),
                  child: const Text(
                    '🟢 Acceso Total',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: controller.selectedIndex.value == 0,
                  onTap: () {
                    controller.cambiarVista(0);
                    Get.back();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.construction,
                  title: 'Obras',
                  isSelected: controller.selectedIndex.value == 1,
                  onTap: () {
                    controller.cambiarVista(1);
                    Get.back();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.layers,
                  title: 'Pisos',
                  isSelected: controller.selectedIndex.value == 2,
                  onTap: () {
                    controller.cambiarVista(2);
                    Get.back();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Usuarios',
                  isSelected: controller.selectedIndex.value == 3,
                  onTap: () {
                    controller.cambiarVista(3);
                    Get.back();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.pending_actions,
                  title: 'Solicitudes',
                  isSelected: controller.selectedIndex.value == 4,
                  onTap: () {
                    controller.cambiarVista(4);
                    Get.back();
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  color: Colors.red,
                  onTap: () => _cerrarSesion(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (isSelected ? Colors.blue : Colors.blueGrey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (isSelected ? Colors.blue : Colors.blueGrey[800]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  // ============================================================
  // BODY - Cambia según el índice seleccionado
  // ============================================================
  Widget _buildBody(BuildContext context, AdminController controller) {
    switch (controller.selectedIndex.value) {
      case 0:
        return _buildDashboard(controller);
      case 1:
        // ✅ REUTILIZAR VISTA DE OBRAS
        return const ObrasView();
      case 2:
        // ✅ REUTILIZAR VISTA DE PISOS
        return _buildPisosSelector(controller);
      case 3:
        // ✅ VISTA DE USUARIOS (propia del admin)
        return _buildUsuariosView(controller);
      case 4:
        // ✅ REUTILIZAR VISTA DE SOLICITUDES
        return const SolicitudesAccesoView();  // ✅ VISTA REUTILIZADA
      default:
        return _buildDashboard(controller);
    }
  }

  // ============================================================
  // SELECTOR DE OBRA PARA PISOS
  // ============================================================
  Widget _buildPisosSelector(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona una obra para ver sus pisos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.obras.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.construction, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay obras disponibles'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.obras.length,
                itemBuilder: (context, index) {
                  final obraMap = controller.obras[index];
                  final obra = ObraModel(
                    idObra: obraMap['id_obra'] as int,
                    nombre: obraMap['nombre'] as String,
                    direccion: obraMap['direccion'] as String?,
                    latitud: (obraMap['latitud'] as num?)?.toDouble(),
                    longitud: (obraMap['longitud'] as num?)?.toDouble(),
                    estado: obraMap['estado'] as bool? ?? true,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.layers, color: Colors.white),
                      ),
                      title: Text(
                        obra.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(obra.direccion ?? 'Sin dirección'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PisosView(obra: obra),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1. DASHBOARD
  // ============================================================
  Widget _buildDashboard(AdminController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen general del sistema',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Obras',
                  value: controller.totalObras.value.toString(),
                  icon: Icons.construction,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Usuarios',
                  value: controller.totalUsuarios.value.toString(),
                  icon: Icons.people,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Materiales',
                  value: controller.totalMateriales.value.toString(),
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Solicitudes Pendientes',
                  value: controller.solicitudesPendientes.value.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Solicitudes Recientes
          Obx(() {
            if (controller.solicitudesRecientes.isEmpty) {
              return const SizedBox();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solicitudes Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A32),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.solicitudesRecientes.length > 5
                        ? 5
                        : controller.solicitudesRecientes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final solicitud = controller.solicitudesRecientes[index];
                      final estado = solicitud['estado'] ?? 'PENDIENTE';
                      final usuario = solicitud['usuarios'] as Map?;
                      final obra = solicitud['obras'] as Map?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getEstadoColor(estado),
                          child: Text(
                            (estado[0] ?? 'P').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          usuario != null
                              ? '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'
                              : 'Usuario',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          obra != null
                              ? obra['nombre'] ?? 'Sin obra'
                              : 'Sin obra',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado.toLowerCase(),
                            style: TextStyle(
                              color: _getEstadoColor(estado),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // 2. USUARIOS - Vista completa
  // ============================================================
  Widget _buildUsuariosView(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Usuarios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A32),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  'Total: ${controller.usuarios.length}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.usuarios.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay usuarios registrados'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = controller.usuarios[index];
                  final esAdmin = usuario['rol'] == 'administrador' ||
                                  usuario['rol'] == 'admin';
                  final obras = usuario['obras'] as List? ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esAdmin ? Colors.green : Colors.blue,
                        child: Text(
                          (usuario['nombre']?[0] ?? 'U').toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario['telefono'] ?? 'Sin teléfono'),
                          if (usuario['correo'] != null && usuario['correo'].isNotEmpty)
                            Text(
                              usuario['correo'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'Rol: ${usuario['rol'] ?? 'Sin rol'}',
                            style: TextStyle(
                              color: esAdmin ? Colors.green : Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (obras.isNotEmpty)
                            Text(
                              'Obras: ${obras.join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: esAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS REUTILIZABLES
  // ============================================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  Color _getEstadoColor(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'APROBADA':
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADA':
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authController = AuthController();
        await authController.cerrarSesion();

        if (context.mounted) {
          Get.delete<AdminController>();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
          );
        }
      } catch (e) {
        // Manejar error silenciosamente
      }
    }
  }
}