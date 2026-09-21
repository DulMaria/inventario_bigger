class InputValidators {
  static String? validarNombre(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu $campo';
    }
    // Letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras';
    }
    // No espacios dobles
    if (value.contains('  ')) {
      return 'No uses espacios adicionales';
    }
    // No caracteres repetidos > 2
    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
      return 'Caracteres repetidos inválidos';
    }
    return null;
  }

  static String? validarCorreo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo';
    }
    final correoValido = RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$');
    if (!correoValido.hasMatch(value)) {
      return 'Ingresa un correo válido (ej: u@dominio.com)';
    }
    return null;
  }

  static String? validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length > 8) {
      return 'Máximo 8 caracteres permitidos';
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
      return 'No uses demasiados caracteres repetidos';
    }
    return null;
  }
}
