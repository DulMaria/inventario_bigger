import '../service/piso_service.dart';
import '../../../models/piso_model.dart';

class PisoController {
  final PisoService _pisoService = PisoService();

  // ============================================================
  // VALIDAR NOMBRE
  // ============================================================

  void _validarNombre(String nombre) {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception('Ingrese el nombre del piso');
    }

    if (nombreLimpio.length < 3) {
      throw Exception('El nombre del piso debe tener al menos 3 caracteres');
    }

    if (nombreLimpio.length > 100) {
      throw Exception('El nombre del piso no puede superar los 100 caracteres');
    }

    // Debe contener al menos una letra.
    final contieneLetra = RegExp(
      r'[A-Za-zÁÉÍÓÚáéíóúÑñÜü]',
    ).hasMatch(nombreLimpio);

    if (!contieneLetra) {
      throw Exception('El nombre del piso debe contener al menos una letra');
    }

    // Solo letras, números y espacios.
    final nombreValido = RegExp(
      r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü0-9 ]+$',
    ).hasMatch(nombreLimpio);

    if (!nombreValido) {
      throw Exception(
        'El nombre del piso solo puede contener letras, números y espacios',
      );
    }
  }

  // ============================================================
  // VALIDAR TIPO DE PISO
  // ============================================================

  void _validarTipoPiso(String tipoPiso) {
    final tipo = tipoPiso.trim().toUpperCase();

    const tiposPermitidos = ['NORMAL', 'SOTANO', 'TERRAZA'];

    if (!tiposPermitidos.contains(tipo)) {
      throw Exception('El tipo de piso no es válido');
    }
  }

  // ============================================================
  // VALIDAR NÚMERO DE PISO
  // ============================================================

  void _validarNumeroPiso({
    required String tipoPiso,
    required int? numeroPiso,
  }) {
    final tipo = tipoPiso.trim().toUpperCase();

    // TERRAZA no utiliza número
    if (tipo == 'TERRAZA') {
      if (numeroPiso != null) {
        throw Exception('La terraza no debe utilizar número de piso');
      }

      return;
    }

    // NORMAL y SOTANO necesitan número
    if (numeroPiso == null) {
      throw Exception('El número de piso es obligatorio');
    }

    // Nunca permitimos el 0
    if (numeroPiso == 0) {
      throw Exception('El número de piso no puede ser 0');
    }

    // PISOS NORMALES
    if (tipo == 'NORMAL') {
      if (numeroPiso < 1) {
        throw Exception('Los pisos normales deben utilizar números positivos');
      }
    }

    // SÓTANOS
    if (tipo == 'SOTANO') {
      if (numeroPiso >= 0) {
        throw Exception('Los sótanos deben utilizar números negativos');
      }
    }
  }

  // ============================================================
  // CREAR PISO
  // ============================================================

  Future<PisoModel> crearPiso({
    required int idObra,
    required String nombre,
    required String tipoPiso,
    int? numeroPiso,
  }) async {
    final nombreLimpio = nombre.trim();
    final tipoLimpio = tipoPiso.trim().toUpperCase();

    _validarNombre(nombreLimpio);
    _validarTipoPiso(tipoLimpio);

    _validarNumeroPiso(tipoPiso: tipoLimpio, numeroPiso: numeroPiso);

    // ----------------------------------------------------------
    // NOMBRE DUPLICADO
    // ----------------------------------------------------------

    final existeNombre = await _pisoService.existePisoConNombre(
      idObra: idObra,
      nombre: nombreLimpio,
    );

    if (existeNombre) {
      throw Exception('Ya existe un piso con el nombre "$nombreLimpio"');
    }

    // ----------------------------------------------------------
    // NÚMERO DUPLICADO
    // ----------------------------------------------------------

    final existeNumero = await _pisoService.existeNumeroPiso(
      idObra: idObra,
      numeroPiso: numeroPiso,
    );

    if (existeNumero) {
      throw Exception('Ya existe un piso con el número $numeroPiso');
    }

    return await _pisoService.crearPiso(
      idObra: idObra,
      nombre: nombreLimpio,
      tipoPiso: tipoLimpio,
      numeroPiso: numeroPiso,
    );
  }

  // ============================================================
  // OBTENER PISOS
  // ============================================================

  Future<List<PisoModel>> obtenerPisos(int idObra) async {
    return await _pisoService.obtenerPisos(idObra);
  }

  // ============================================================
  // EDITAR PISO
  // ============================================================

  Future<PisoModel> editarPiso({
    required int idPiso,
    required int idObra,
    required String nombre,
    required String estadoObra,
    required String tipoPiso,
    int? numeroPiso,
  }) async {
    final nombreLimpio = nombre.trim();
    final tipoLimpio = tipoPiso.trim().toUpperCase();

    _validarNombre(nombreLimpio);
    _validarTipoPiso(tipoLimpio);

    _validarNumeroPiso(tipoPiso: tipoLimpio, numeroPiso: numeroPiso);

    // ----------------------------------------------------------
    // NOMBRE DUPLICADO
    // ----------------------------------------------------------

    final existeNombre = await _pisoService.existeOtroPisoConNombre(
      idObra: idObra,
      idPisoActual: idPiso,
      nombre: nombreLimpio,
    );

    if (existeNombre) {
      throw Exception('Ya existe otro piso con el nombre "$nombreLimpio"');
    }

    // ----------------------------------------------------------
    // NÚMERO DUPLICADO
    // ----------------------------------------------------------

    final existeNumero = await _pisoService.existeOtroNumeroPiso(
      idObra: idObra,
      idPisoActual: idPiso,
      numeroPiso: numeroPiso,
    );

    if (existeNumero) {
      throw Exception('Ya existe otro piso con el número $numeroPiso');
    }

    return await _pisoService.editarPiso(
      idPiso: idPiso,
      nombre: nombreLimpio,
      estadoObra: estadoObra,
      tipoPiso: tipoLimpio,
      numeroPiso: numeroPiso,
    );
  }
}
