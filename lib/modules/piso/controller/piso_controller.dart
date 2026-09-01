import '../service/piso_service.dart';
import '../../../models/piso_model.dart';

class PisoController {
  final PisoService _pisoService = PisoService();

  // Estados en orden de avance sucesivo
  static const List<String> ordenEstados = [
    'NO INICIADO',
    'OBRA BRUTA',
    'OBRA FINA',
    'FINALIZADO',
  ];

  // ============================================================
  // VALIDAR NOMBRE
  // ============================================================

  void _validarNombre(String nombre) {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception('Ingrese el nombre del piso');
    }

    if (nombreLimpio.length < 2) {
      throw Exception('El nombre del piso debe tener al menos 2 caracteres');
    }

    if (nombreLimpio.length > 100) {
      throw Exception('El nombre del piso no puede superar los 100 caracteres');
    }

    // Debe contener al menos una letra o número.
    final contieneLetraONumero = RegExp(
      r'[A-Za-zÁÉÍÓÚáéíóúÑñÜü0-9]',
    ).hasMatch(nombreLimpio);

    if (!contieneLetraONumero) {
      throw Exception('El nombre del piso debe ser válido');
    }
  }

  // ============================================================
  // VALIDAR TIPO DE PISO
  // ============================================================

  void _validarTipoPiso(String tipoPiso) {
    final tipo = tipoPiso.trim().toUpperCase();

    const tiposPermitidos = ['NORMAL', 'SOTANO', 'TERRAZA', 'ESPECIAL'];

    if (!tiposPermitidos.contains(tipo)) {
      throw Exception('El tipo de piso no es válido');
    }
  }

  // ============================================================
  // VALIDAR NÚMERO DE PISO
  // ============================================================

  void _validarNumeroPiso({
    required String tipoPiso,
    required int numeroPiso,
  }) {
    final tipo = tipoPiso.trim().toUpperCase();

    // Nunca permitimos el 0
    if (numeroPiso == 0) {
      throw Exception('El número de piso no puede ser 0');
    }

    // PISOS SOBRE LOZA (NORMAL, TERRAZA, ESPECIAL)
    if (tipo == 'NORMAL' || tipo == 'TERRAZA' || tipo == 'ESPECIAL') {
      if (numeroPiso < 1) {
        throw Exception('Los niveles superiores deben tener un número positivo (1, 2, 3...)');
      }
    }

    // SÓTANOS
    if (tipo == 'SOTANO') {
      if (numeroPiso >= 0) {
        throw Exception('Los sótanos deben utilizar números negativos (-1, -2, -3...)');
      }
    }
  }

  // ============================================================
  // VALIDAR TRANSICIÓN DE ESTADO (SUCESIVOS)
  // ============================================================

  void validarTransicionEstado({
    required String estadoActual,
    required String nuevoEstado,
  }) {
    if (estadoActual == nuevoEstado) {
      return;
    }

    final indexActual = ordenEstados.indexOf(estadoActual);
    final indexNuevo = ordenEstados.indexOf(nuevoEstado);

    if (indexActual == -1 || indexNuevo == -1) {
      throw Exception('Estado no reconocido');
    }

    // Solo se permite avanzar exactamente al siguiente estado (o mantenerse)
    if (indexNuevo != indexActual + 1) {
      if (indexNuevo < indexActual) {
        throw Exception(
          'No se puede retroceder de "$estadoActual" a "$nuevoEstado"',
        );
      }
      throw Exception(
        'El avance debe ser sucesivo. De "$estadoActual" solo se puede pasar a "${ordenEstados[indexActual + 1]}".',
      );
    }
  }

  // ============================================================
  // OBTENER ESTADOS PERMITIDOS PARA EDICIÓN
  // ============================================================

  List<String> obtenerEstadosPermitidos(String estadoActual) {
    final indexActual = ordenEstados.indexOf(estadoActual);
    if (indexActual == -1) {
      return ordenEstados;
    }

    final List<String> permitidos = [estadoActual];
    if (indexActual + 1 < ordenEstados.length) {
      permitidos.add(ordenEstados[indexActual + 1]);
    }
    return permitidos;
  }

  // ============================================================
  // CREAR PISO
  // ============================================================

  Future<PisoModel> crearPiso({
    required int idObra,
    required String nombre,
    required String tipoPiso,
    required int numeroPiso,
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
    required String estadoActual,
    required String nuevoEstadoObra,
    required String tipoPiso,
    required int numeroPiso,
  }) async {
    final nombreLimpio = nombre.trim();
    final tipoLimpio = tipoPiso.trim().toUpperCase();

    _validarNombre(nombreLimpio);
    _validarTipoPiso(tipoLimpio);
    _validarNumeroPiso(tipoPiso: tipoLimpio, numeroPiso: numeroPiso);
    validarTransicionEstado(
      estadoActual: estadoActual,
      nuevoEstado: nuevoEstadoObra,
    );

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
      estadoObra: nuevoEstadoObra,
      tipoPiso: tipoLimpio,
      numeroPiso: numeroPiso,
    );
  }
}
