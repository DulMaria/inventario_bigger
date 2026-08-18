import '../../../models/obra_model.dart';
import '../service/obra_service.dart';

class ObraController {
  final ObraService _obraService = ObraService();

  // ============================================================
  // VALIDAR NOMBRE
  // ============================================================

  void _validarNombre(String nombre) {
    final nombreLimpio = nombre.trim();

    //Vacio
    if (nombreLimpio.isEmpty) {
      throw Exception('Ingrese el nombre de la obra');
    }

    //Solo espacios
    if (nombreLimpio.replaceAll(' ', '').isEmpty) {
      throw Exception('El nombre de la obra no es válido');
    }

    //Minimo de caracteres
    if (nombreLimpio.length < 3) {
      throw Exception('Elnombre de la obra debe tener al menos 3 caracteres');
    }

    //Maximo de caracteres
    if (nombreLimpio.length > 100) {
      throw Exception(
        'El nombre de la obra no puede superar los 100 caracteres',
      );
    }

    // Debe contener al menos una letra
    final contieneLetra = RegExp(
      r'[A-Za-zÁÉÍÓÚáéíóúÑñÜü]',
    ).hasMatch(nombreLimpio);

    if (!contieneLetra) {
      throw Exception('El nombre de la obra debe contener al menos una letra');
    }

    // No permitir caracteres especiales
    final nombreValido = RegExp(
      r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü0-9 ]+$',
    ).hasMatch(nombreLimpio);

    if (!nombreValido) {
      throw Exception('El nombre de la obra contiene caracteres no permitidos');
    }
  }

  // ============================================================
  // VALIDAR DIRECCIÓN
  // ============================================================

  void _validarDireccion(String? direccion) {
    if (direccion == null || direccion.trim().isEmpty) {
      throw Exception('Ingrese o seleccione la dirección de la obra');
    }

    final direccionLimpia = direccion.trim();

    // Mínimo de caracteres
    if (direccionLimpia.length < 5) {
      throw Exception('La dirección debe tener al menos 5 caracteres');
    }

    // Máximo de caracteres
    if (direccionLimpia.length > 200) {
      throw Exception('La dirección no puede superar los 200 caracteres');
    }

    // Debe contener al menos una letra
    final contieneLetra = RegExp(
      r'[A-Za-zÁÉÍÓÚáéíóúÑñÜü]',
    ).hasMatch(direccionLimpia);

    if (!contieneLetra) {
      throw Exception('La dirección debe contener al menos una letra');
    }

    // No permitir que sea únicamente numérica
    final esSoloNumeros = RegExp(r'^[0-9\s]+$').hasMatch(direccionLimpia);

    if (esSoloNumeros) {
      throw Exception('Ingrese una dirección válida');
    }

    // Caracteres permitidos para direcciones
    final direccionValida = RegExp(
      r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü0-9\s.,#/\-]+$",
    ).hasMatch(direccionLimpia);

    if (!direccionValida) {
      throw Exception('La dirección contiene caracteres no permitidos');
    }
  }

  // ============================================================
  // VALIDAR UBICACIÓN
  // ============================================================

  void _validarUbicacion(double? latitud, double? longitud) {
    // Deben existir ambas coordenadas
    if (latitud == null || longitud == null) {
      throw Exception('Debe seleccionar la ubicación de la obra en el mapa');
    }

    // Las coordenadas no pueden ser NaN ni infinitas
    if (latitud.isNaN || latitud.isInfinite) {
      throw Exception('La latitud seleccionada no es válida');
    }

    if (longitud.isNaN || longitud.isInfinite) {
      throw Exception('La longitud seleccionada no es válida');
    }

    // Rango válido de latitud
    if (latitud < -90 || latitud > 90) {
      throw Exception('La latitud está fuera del rango válido');
    }

    // Rango válido de longitud
    if (longitud < -180 || longitud > 180) {
      throw Exception('La longitud está fuera del rango válido');
    }
  }

  // ============================================================
  // CREAR OBRA
  // ============================================================

  Future<ObraModel> crearObra({
    required String nombre,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    final nombreLimpio = nombre.trim();
    final direccionLimpia = direccion?.trim();

    // Validaciones generales
    _validarNombre(nombreLimpio);
    _validarDireccion(direccionLimpia);
    _validarUbicacion(latitud, longitud);

    // Validar nombre duplicado
    final existe = await existeObraConNombre(nombreLimpio);

    if (existe) {
      throw Exception('Ya existe una obra con el nombre "$nombreLimpio"');
    }

    return await _obraService.crearObra(
      nombre: nombreLimpio,
      direccion: direccionLimpia,
      latitud: latitud,
      longitud: longitud,
    );
  }

  // ============================================================
  // OBTENER OBRAS
  // ============================================================

  Future<List<ObraModel>> obtenerObras() async {
    return await _obraService.obtenerObras();
  }

  // ============================================================
  // EDITAR OBRA
  // ============================================================

  Future<ObraModel> editarObra({
    required int idObra,
    required String nombre,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    final nombreLimpio = nombre.trim();
    final direccionLimpia = direccion?.trim();

    // Reutilizamos las mismas validaciones
    _validarNombre(nombreLimpio);
    _validarDireccion(direccionLimpia);
    _validarUbicacion(latitud, longitud);

    // En edición solamente cambia la comprobación
    // porque debemos excluir la obra actual.
    final existe = await existeOtraObraConNombre(nombreLimpio, idObra);

    if (existe) {
      throw Exception('Ya existe otra obra con el nombre "$nombreLimpio"');
    }

    return await _obraService.editarObra(
      idObra: idObra,
      nombre: nombreLimpio,
      direccion: direccionLimpia,
      latitud: latitud,
      longitud: longitud,
    );
  }

  // ============================================================
  // COMPROBAR SI EXISTE UNA OBRA CON EL NOMBRE
  // ============================================================

  Future<bool> existeObraConNombre(String nombre) async {
    return await _obraService.existeObraConNombre(nombre);
  }

  // ============================================================
  // COMPROBAR SI EXISTE OTRA OBRA CON EL MISMO NOMBRE
  // ============================================================

  Future<bool> existeOtraObraConNombre(String nombre, int idObraActual) async {
    return await _obraService.existeOtraObraConNombre(nombre, idObraActual);
  }
}
