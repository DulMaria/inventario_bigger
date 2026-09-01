// lib/modules/administrador/controller/admin_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/admin_service.dart';

class AdminController extends GetxController {
  final AdminService _adminService = AdminService();

  // ============================================================
  // ESTADOS DE NAVEGACIÓN
  // ============================================================
  var selectedIndex = 0.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // ============================================================
  // DATOS DEL DASHBOARD
  // ============================================================
  var totalObras = 0.obs;
  var totalUsuarios = 0.obs;
  var totalMateriales = 0.obs;
  var solicitudesPendientes = 0.obs;
  var solicitudesRecientes = <Map<String, dynamic>>[].obs;

  // ============================================================
  // LISTAS DE DATOS
  // ============================================================
  var obras = <Map<String, dynamic>>[].obs;
  var usuarios = <Map<String, dynamic>>[].obs;
  var solicitudes = <Map<String, dynamic>>[].obs;
  var roles = <Map<String, dynamic>>[].obs;

  // ============================================================
  // DATOS DEL ADMIN (PERFIL)
  // ============================================================
  var adminNombre = ''.obs;
  var adminRol = ''.obs;
  var adminTelefono = ''.obs;
  var adminCorreo = ''.obs;

  // ============================================================
  // INICIALIZAR
  // ============================================================
  @override
  void onInit() {
    super.onInit();
    cargarTodosLosDatos();
  }

  // ============================================================
  // CARGAR TODOS LOS DATOS
  // ============================================================
  Future<void> cargarTodosLosDatos() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        cargarDashboard(),
        cargarObras(),
        cargarUsuarios(),
        cargarSolicitudes(),
        cargarRoles(),
        cargarAdminData(),
      ]);
    } catch (e) {
      errorMessage.value = 'Error al cargar datos: $e';
      print('Error en AdminController: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CARGAR DASHBOARD
  // ============================================================
  Future<void> cargarDashboard() async {
    try {
      final data = await _adminService.getDashboardStats();
      totalObras.value = data['total_obras'] ?? 0;
      totalUsuarios.value = data['total_usuarios'] ?? 0;
      totalMateriales.value = data['total_materiales'] ?? 0;
      solicitudesPendientes.value = data['solicitudes_pendientes'] ?? 0;

      final recientes = data['solicitudes_recientes'] as List?;
      if (recientes != null) {
        solicitudesRecientes.value = recientes.cast<Map<String, dynamic>>();
      } else {
        solicitudesRecientes.value = [];
      }
    } catch (e) {
      print('Error al cargar dashboard: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARGAR OBRAS
  // ============================================================
  Future<void> cargarObras() async {
    try {
      final data = await _adminService.getObras();
      obras.value = data;
    } catch (e) {
      print('Error al cargar obras: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARGAR USUARIOS
  // ============================================================
  Future<void> cargarUsuarios() async {
    try {
      final data = await _adminService.getUsuarios();
      usuarios.value = data;
    } catch (e) {
      print('Error al cargar usuarios: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARGAR SOLICITUDES (SOLO UNA VEZ)
  // ============================================================
  Future<void> cargarSolicitudes() async {
    try {
      print('🔄 [ADMIN] Cargando solicitudes...');
      final data = await _adminService.getSolicitudes();
      print('✅ [ADMIN] Solicitudes cargadas: ${data.length}');
      solicitudes.value = data;
    } catch (e) {
      print('❌ [ADMIN] Error al cargar solicitudes: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARGAR ROLES
  // ============================================================
  Future<void> cargarRoles() async {
    try {
      final data = await _adminService.getRoles();
      roles.value = data;
    } catch (e) {
      print('Error al cargar roles: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARGAR DATOS DEL ADMIN (PERFIL)
  // ============================================================
  Future<void> cargarAdminData() async {
    try {
      final data = await _adminService.getAdminData();
      if (data != null) {
        adminNombre.value = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}';
        adminTelefono.value = data['telefono'] ?? '';
        adminCorreo.value = data['correo'] ?? '';

        final rolData = await _adminService.getRoles();
        final adminRolData = rolData.firstWhere(
          (r) => r['id_rol'] == 8,
          orElse: () => {'nombre': 'Administrador'},
        );
        adminRol.value = adminRolData['nombre'] ?? 'Administrador';
      }
    } catch (e) {
      print('Error al cargar admin data: $e');
    }
  }

  // ============================================================
  // ACCIONES - APROBAR SOLICITUD
  // ============================================================
  Future<void> aprobarSolicitud({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    try {
      isLoading.value = true;
      await _adminService.aprobarSolicitud(
        idSolicitud: idSolicitud,
        idUsuario: idUsuario,
        idObra: idObra,
        idRol: idRol,
      );
      await cargarSolicitudes();
      await cargarUsuarios();
      Get.snackbar(
        'Éxito',
        'Solicitud aprobada correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo aprobar la solicitud: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ACCIONES - RECHAZAR SOLICITUD
  // ============================================================
  Future<void> rechazarSolicitud({
    required int idSolicitud,
    String? observacion,
  }) async {
    try {
      isLoading.value = true;
      await _adminService.rechazarSolicitud(
        idSolicitud: idSolicitud,
        observacion: observacion,
      );
      await cargarSolicitudes();
      Get.snackbar(
        'Éxito',
        'Solicitud rechazada correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo rechazar la solicitud: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ACCIONES - APROBAR CON OTRO ROL
  // ============================================================
  Future<void> aprobarConRol({
    required int idSolicitud,
    required int idUsuario,
    required int idObra,
    required int idRol,
  }) async {
    try {
      isLoading.value = true;
      await _adminService.aprobarConRol(
        idSolicitud: idSolicitud,
        idUsuario: idUsuario,
        idObra: idObra,
        idRol: idRol,
      );
      await cargarSolicitudes();
      await cargarUsuarios();
      Get.snackbar(
        'Éxito',
        'Solicitud aprobada con el rol seleccionado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo aprobar la solicitud: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CAMBIAR VISTA
  // ============================================================
  void cambiarVista(int index) {
    selectedIndex.value = index;
  }

  // ============================================================
  // REFRESCAR
  // ============================================================
  void refreshDashboard() {
    cargarTodosLosDatos();
  }
}