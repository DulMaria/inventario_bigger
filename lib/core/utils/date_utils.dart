// lib/core/utils/date_utils.dart

class DateUtilsBolivia {
  /// Convierte cualquier DateTime (UTC o servidor) a Hora Boliviana (UTC-4)
  static DateTime toBoliviaTime(DateTime date) {
    final utc = date.toUtc();
    return utc.subtract(const Duration(hours: 4));
  }

  /// Formatea la fecha y hora en zona horaria UTC-4 (Bolivia)
  /// Ejemplo: '24/09/2026 19:45'
  static String formatBolivia(DateTime date, {bool includeTime = true}) {
    final bolivia = toBoliviaTime(date);
    final d = bolivia.day.toString().padLeft(2, '0');
    final m = bolivia.month.toString().padLeft(2, '0');
    final y = bolivia.year;
    if (!includeTime) {
      return '$d/$m/$y';
    }
    final hh = bolivia.hour.toString().padLeft(2, '0');
    final mm = bolivia.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}
