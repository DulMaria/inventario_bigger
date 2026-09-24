// lib/modules/administrador/view/admin_page.dart
import 'package:flutter/material.dart';
import 'package:inventario_bigger/core/config/app_colors.dart';
import 'package:get/get.dart';
import '../controller/admin_controller.dart';

// ✅ IMPORTAR VISTAS EXISTENTES
import '../../obra/view/obra_view.dart';
import '../../piso/view/pisos_view.dart';
import '../../solicitud_acceso/view/solicitudes_acceso_view.dart';
import '../../../models/obra_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/login_view.dart';
import 'admin_proformas_view.dart';
import 'admin_almacen_view.dart';
import 'perfil_usuario_view.dart';
import '../../../core/config/app_colors.dart';



class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWebLayout = constraints.maxWidth >= 900;

        if (isWebLayout) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Row(
              children: [
                // PERSISTENT SIDEBAR FOR WEB/DESKTOP
                SizedBox(
                  width: 280,
                  child: _buildDrawerContent(context, controller, isWeb: true),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // MAIN CONTENT AREA FOR WEB
                Expanded(
                  child: Scaffold(
                    backgroundColor: AppColors.backgroundLight,
                    appBar: AppBar(
                      title: Obx(() {
                        final titles = [
                          'Dashboard',
                          'Obras',
                          'Pisos',
                          'Usuarios y Accesos por Obra',
                          'Solicitudes de Acceso',
                          'Proformas y Cotizaciones',
                          'Almacén (Global)',
                          'Mi Perfil',
                        ];
                        return Text(
                          controller.selectedIndex.value < titles.length
                              ? titles[controller.selectedIndex.value]
                              : 'Administrador',
                        );
                      }),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.refreshDashboard,
                          tooltip: 'Refrescar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () => controller.cambiarVista(7),
                          tooltip: 'Mi Perfil',
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
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.errorMessage.value.isNotEmpty) {
                        return _buildErrorState(controller);
                      }
                      return _buildBody(context, controller, isWebLayout: true);
                    }),
                  ),
                ),
              ],
            ),
          );
        }

        // MOBILE LAYOUT
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            child: _buildDrawerContent(context, controller, isWeb: false),
          ),
          appBar: AppBar(
            title: Obx(() {
              final titles = [
                'Dashboard',
                'Obras',
                'Pisos',
                'Usuarios y Accesos por Obra',
                'Solicitudes de Acceso',
                'Proformas y Cotizaciones',
                'Almacén (Global)',
                'Mi Perfil',
              ];
              return Text(
                controller.selectedIndex.value < titles.length
                    ? titles[controller.selectedIndex.value]
                    : 'Administrador',
              );
            }),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshDashboard,
                tooltip: 'Refrescar',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => controller.cambiarVista(7),
                tooltip: 'Mi Perfil',
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
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(controller);
            }
            return _buildBody(context, controller, isWebLayout: false);
          }),
        );
      },
    );
  }

  Widget _buildErrorState(AdminController controller) {
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

  // ============================================================
  // DRAWER / SIDEBAR CONTENT
  // ============================================================
  Widget _buildDrawerContent(
    BuildContext context,
    AdminController controller, {
    required bool isWeb,
  }) {
    return Column(
      children: [
        // Header - Perfil del Administrador
        InkWell(
          onTap: () {
            controller.cambiarVista(7);
            if (!isWeb) Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Text(
                    controller.adminNombre.value.isNotEmpty
                        ? controller.adminNombre.value
                        : 'Administrador',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(
                  () => Text(
                    controller.adminRol.value.isNotEmpty
                        ? controller.adminRol.value
                        : 'Administrador',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[400]!.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[400]!),
                  ),
                  child: const Text(
                    '🟢 Acceso Total (Global)',
                    style: TextStyle(color: AppColors.surface, fontSize: 11),
                  ),
                ),
              ],
            ),
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
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.construction,
                title: 'Obras',
                isSelected: controller.selectedIndex.value == 1,
                onTap: () {
                  controller.cambiarVista(1);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.layers,
                title: 'Pisos',
                isSelected: controller.selectedIndex.value == 2,
                onTap: () {
                  controller.cambiarVista(2);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.people_alt_outlined,
                title: 'Usuarios y Accesos',
                isSelected: controller.selectedIndex.value == 3,
                onTap: () {
                  controller.cambiarVista(3);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.assignment_turned_in,
                title: 'Solicitudes de Acceso',
                isSelected: controller.selectedIndex.value == 4,
                onTap: () {
                  controller.cambiarVista(4);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.receipt_long,
                title: 'Proformas / Cotizaciones',
                isSelected: controller.selectedIndex.value == 5,
                onTap: () {
                  controller.cambiarVista(5);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.warehouse_rounded,
                title: 'Almacén (Global)',
                isSelected: controller.selectedIndex.value == 6,
                onTap: () {
                  controller.cambiarVista(6);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.person_outline,
                title: 'Mi Perfil',
                isSelected: controller.selectedIndex.value == 7,
                onTap: () {
                  controller.cambiarVista(7);
                  if (!isWeb) Navigator.pop(context);
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                color: Colors.red,
                isSelected: false,
                onTap: () => _cerrarSesion(context),
              ),
            ],
          ),
        ),
      ],
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
        color:
            color ??
            (isSelected ? AppColors.primary : const Color(0xFF1E293B).withValues(alpha: 0.7)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              color ??
              (isSelected ? AppColors.primary : const Color(0xFF1E293B).withValues(alpha: 0.7)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
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
  Widget _buildBody(
    BuildContext context,
    AdminController controller, {
    required bool isWebLayout,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Builder(
        key: ValueKey<int>(controller.selectedIndex.value),
        builder: (context) {
          switch (controller.selectedIndex.value) {
            case 0:
              return _buildDashboard(controller, isWebLayout: isWebLayout);
            case 1:
              return const ObrasView();
            case 2:
              return _buildPisosSelector(controller);
            case 3:
              return _buildUsuariosView(
                context,
                controller,
                isWebLayout: isWebLayout,
              );
            case 4:
              return const SolicitudesAccesoView(isEmbedded: true);
            case 5:
              return const AdminProformasView();
            case 6:
              return const AdminAlmacenView();
            case 7:
              return const PerfilUsuarioView(isEmbedded: true);
            default:
              return _buildDashboard(controller, isWebLayout: isWebLayout);
          }
        },
      ),
    );
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
                        child: Icon(Icons.layers, color: AppColors.surface),
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
  // 1. DASHBOARD RESPONSIVO MEJORADO
  // ============================================================
  Widget _buildDashboard(
    AdminController controller, {
    required bool isWebLayout,
  }) {
    final now = DateTime.now();
    final fechaStr = '${now.day}/${now.month}/${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Colors.indigo.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          '👋 ¡Bienvenido de nuevo, ${controller.adminNombre.value.isNotEmpty ? controller.adminNombre.value : "Administrador"}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📅 $fechaStr • Supervisión Global de Obras, Cotizaciones y Almacén en Tiempo Real',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: AppColors.surface,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sección de Atajos Rápidos
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionTile(
                  icon: Icons.construction,
                  label: 'Obras y Pisos',
                  color: AppColors.primary,
                  onTap: () => controller.cambiarVista(1),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.people_alt,
                  label: 'Usuarios y Accesos',
                  color: Colors.green,
                  onTap: () => controller.cambiarVista(3),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.receipt_long,
                  label: 'Proformas y Cotizar',
                  color: Colors.amber.shade800,
                  onTap: () => controller.cambiarVista(5),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.warehouse_rounded,
                  label: 'Almacén Global',
                  color: Colors.purple,
                  onTap: () => controller.cambiarVista(6),
                ),
                const SizedBox(width: 10),
                _buildQuickActionTile(
                  icon: Icons.person,
                  label: 'Mi Perfil',
                  color: Colors.teal,
                  onTap: () => controller.cambiarVista(7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Métricas Globales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A32),
            ),
          ),
          const SizedBox(height: 12),

          // Tarjetas de estadísticas (Grid responsivo)
          if (isWebLayout)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Obras Registradas',
                    value: controller.totalObras.value.toString(),
                    icon: Icons.construction,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Usuarios Totales',
                    value: controller.totalUsuarios.value.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Materiales en Catálogo',
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
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Obras Registradas',
                    value: controller.totalObras.value.toString(),
                    icon: Icons.construction,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Usuarios Totales',
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
                    title: 'Materiales Catálogo',
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
          ],

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.solicitudesRecientes.length > 5
                        ? 5
                        : controller.solicitudesRecientes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
                              color: AppColors.surface,
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
                            color: _getEstadoColor(
                              estado,
                            ).withValues(alpha: 0.1),
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
  // 2. USUARIOS Y ACCESOS POR OBRA (NUEVA VISTA RESPONSIVA)
  // ============================================================
  Widget _buildUsuariosView(
    BuildContext context,
    AdminController controller, {
    required bool isWebLayout,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Usuarios y Accesos por Obra',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2A32),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Inhabilita o habilita el acceso de los usuarios por renuncia o cambio de obra.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    'Total: ${controller.usuarios.length} usuarios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Bar (Search + Dropdown Obras + Dropdown Estado)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Box
                  SizedBox(
                    width: isWebLayout ? 280 : double.infinity,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, correo...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) =>
                          controller.busquedaUsuario.value = val,
                    ),
                  ),

                  // Obra Filter Dropdown
                  Obx(() {
                    return SizedBox(
                      width: isWebLayout ? 200 : double.infinity,
                      child: DropdownButtonFormField<int?>(
                          dropdownColor: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        value: controller.obraFiltro.value,
                        hint: const Text(
                          'Todas las Obras',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Todas las Obras',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...controller.obras.map((o) {
                            return DropdownMenuItem<int?>(
                              value: o['id_obra'] as int?,
                              child: Text(
                                o['nombre'].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => controller.obraFiltro.value = val,
                      ),
                    );
                  }),

                  // Estado Filter Dropdown
                  Obx(() {
                    return SizedBox(
                      width: isWebLayout ? 200 : double.infinity,
                      child: DropdownButtonFormField<String>(
                          dropdownColor: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        value: controller.estadoFiltro.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'TODOS',
                            child: Text(
                              'Todos los Estados',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ACTIVOS',
                            child: Text(
                              '🟢 Solo Activos',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'INHABILITADOS',
                            child: Text(
                              '🔴 Solo Inhabilitados',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.estadoFiltro.value = val;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Cards / List
          Expanded(
            child: Obx(() {
              final query = controller.busquedaUsuario.value
                  .toLowerCase()
                  .trim();
              final idObraFiltro = controller.obraFiltro.value;
              final estadoFiltro = controller.estadoFiltro.value;

              final listaFiltrada = controller.usuarios.where((u) {
                final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'
                    .toLowerCase();
                final correo = (u['correo'] ?? '').toString().toLowerCase();
                final telefono = (u['telefono'] ?? '').toString().toLowerCase();
                final matchQuery =
                    query.isEmpty ||
                    nombre.contains(query) ||
                    correo.contains(query) ||
                    telefono.contains(query);

                if (!matchQuery) return false;

                final esActivoGlobal = u['estado'] == true;
                if (estadoFiltro == 'ACTIVOS' && !esActivoGlobal) return false;
                if (estadoFiltro == 'INHABILITADOS' && esActivoGlobal)
                  return false;

                if (idObraFiltro != null) {
                  final obrasDet = (u['obras_detalladas'] as List? ?? []);
                  final tieneObra = obrasDet.any(
                    (o) => o['id_obra'] == idObraFiltro,
                  );
                  if (!tieneObra) return false;
                }

                return true;
              }).toList();

              if (listaFiltrada.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No se encontraron usuarios con los filtros seleccionados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: listaFiltrada.length,
                itemBuilder: (context, index) {
                  final u = listaFiltrada[index];
                  final idUsuario = u['id_usuario'] as int;
                  final nombreCompleto =
                      '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
                  final esAdmin =
                      u['rol'] == 'administrador' || u['rol'] == 'admin';
                  final esActivoGlobal = u['estado'] == true;
                  final obrasDetalladas = (u['obras_detalladas'] as List? ?? [])
                      .cast<Map<String, dynamic>>();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: esActivoGlobal
                            ? Colors.grey.shade300
                            : Colors.red.shade300,
                        width: esActivoGlobal ? 1 : 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header User Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: !esActivoGlobal
                                    ? Colors.red.shade400
                                    : (esAdmin
                                          ? Colors.green.shade600
                                          : AppColors.primary),
                                child: Text(
                                  (u['nombre']?[0] ?? 'U').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreCompleto,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: esActivoGlobal
                                            ? AppColors.textPrimary
                                            : Colors.red.shade900,
                                        decoration: esActivoGlobal
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '✉️ ${u['correo'] ?? 'Sin correo'} • 📱 ${u['telefono'] ?? 'Sin teléfono'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badges & Global Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esActivoGlobal
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: esActivoGlobal
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      esActivoGlobal
                                          ? '🟢 HABILITADO'
                                          : '🔴 INHABILITADO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: esActivoGlobal
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                  if (!esAdmin) ...[
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => _confirmarCambioEstadoGlobal(
                                        context,
                                        controller,
                                        idUsuario: idUsuario,
                                        nombreUsuario: nombreCompleto,
                                        estadoActual: esActivoGlobal,
                                      ),
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: esActivoGlobal ? Colors.red.shade50 : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: esActivoGlobal ? Colors.red.shade200 : Colors.green.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            esActivoGlobal
                                                ? 'Inhabilitar Global'
                                                : 'Reactivar Global',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: esActivoGlobal
                                                  ? Colors.red.shade700
                                                  : Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Obras vinculadas y sus estados
                          const Text(
                            'Acceso y Estado por Obra:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (obrasDetalladas.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Sin obras vinculadas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: obrasDetalladas.map((obDet) {
                                final idObra = obDet['id_obra'] as int;
                                final nombreObra =
                                    obDet['nombre_obra'] as String;
                                final nombreRol = obDet['nombre_rol'] as String;
                                final esActivoObra = obDet['estado'] == true;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: esActivoObra
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: esActivoObra
                                          ? AppColors.primary
                                          : Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        esActivoObra
                                            ? Icons.business
                                            : Icons.block,
                                        size: 16,
                                        color: esActivoObra
                                            ? AppColors.primary
                                            : Colors.orange.shade900,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$nombreObra ($nombreRol)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: esActivoObra
                                              ? const Color(0xFF1E293B)
                                              : Colors.orange.shade900,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _confirmarCambioEstadoObra(
                                          context,
                                          controller,
                                          idUsuario: idUsuario,
                                          idObra: idObra,
                                          nombreObra: nombreObra,
                                          nombreUsuario: nombreCompleto,
                                          estadoActualObra: esActivoObra,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: esActivoObra
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: esActivoObra ? Colors.red.shade50 : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: esActivoObra ? Colors.red.shade200 : Colors.green.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                esActivoObra
                                                    ? 'Inhabilitar'
                                                    : 'Habilitar',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: esActivoObra
                                                      ? Colors.red.shade900
                                                      : Colors.green.shade900,
                                                ),
                                              ),
                                            ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
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
  // DIÁLOGOS DE CONFIRMACIÓN DE INHABILITACIÓN
  // ============================================================
  Future<void> _confirmarCambioEstadoObra(
    BuildContext context,
    AdminController controller, {
    required int idUsuario,
    required int idObra,
    required String nombreObra,
    required String nombreUsuario,
    required bool estadoActualObra,
  }) async {
    final nuevoEstado = !estadoActualObra;
    final accion = nuevoEstado
        ? 'habilitar'
        : 'inhabilitar por renuncia/salida';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(nuevoEstado ? 'Habilitar en Obra' : 'Inhabilitar en Obra'),
        content: Text(
          '¿Estás seguro de que deseas $accion al usuario "$nombreUsuario" en la obra "$nombreObra"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado ? Colors.green : Colors.red,
              foregroundColor: AppColors.surface,
            ),
            child: Text(nuevoEstado ? 'Sí, Habilitar' : 'Sí, Inhabilitar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.cambiarEstadoUsuarioObra(
        idUsuario: idUsuario,
        idObra: idObra,
        estado: nuevoEstado,
        nombreObra: nombreObra,
      );
    }
  }

  Future<void> _confirmarCambioEstadoGlobal(
    BuildContext context,
    AdminController controller, {
    required int idUsuario,
    required String nombreUsuario,
    required bool estadoActual,
  }) async {
    final nuevoEstado = !estadoActual;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          nuevoEstado
              ? 'Habilitar Usuario Global'
              : 'Inhabilitar Usuario Global',
        ),
        content: Text(
          '¿Estás seguro de que deseas ${nuevoEstado ? "habilitar" : "inhabilitar totalmente"} al usuario "$nombreUsuario"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado ? Colors.green : Colors.red,
              foregroundColor: AppColors.surface,
            ),
            child: Text(nuevoEstado ? 'Sí, Habilitar' : 'Sí, Inhabilitar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.cambiarEstadoUsuarioGlobal(
        idUsuario: idUsuario,
        estado: nuevoEstado,
        nombreUsuario: nombreUsuario,
      );
    }
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
                    color: color.withValues(alpha: 0.1),
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

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
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

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final authController = AuthController();
      await authController.cerrarSesion();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }
}
