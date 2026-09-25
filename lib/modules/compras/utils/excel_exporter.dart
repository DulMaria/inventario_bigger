// lib/modules/compras/utils/excel_exporter.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../models/solicitud_model.dart';
import '../../../core/utils/date_utils.dart';

class MaterialConsolidado {
  final int idMaterial;
  final String codigo;
  final String nombre;
  final String unidadMedida;
  int cantidadTotal;

  MaterialConsolidado({
    required this.idMaterial,
    required this.codigo,
    required this.nombre,
    required this.unidadMedida,
    required this.cantidadTotal,
  });
}

class ExcelExporter {
  // ============================================================
  // CONSOLIDAR MATERIALES (SUMA AUTOMÁTICA DE CANTIDADES POR UNIDAD)
  // ============================================================
  static List<MaterialConsolidado> consolidarMateriales(List<SolicitudModel> solicitudes) {
    final Map<String, MaterialConsolidado> acumulador = {};

    for (final sol in solicitudes) {
      for (final det in sol.detalles) {
        final mat = det.material;
        final idMat = mat?.idMaterial ?? det.idDetalle;
        final codigo = (mat?.codigo != null && mat!.codigo!.trim().isNotEmpty) ? mat.codigo! : '-';
        final nombre = mat?.nombre ?? (mat != null ? 'Material #${mat.idMaterial}' : 'Material');
        final unidad = (det.unidadMedida.isNotEmpty && det.unidadMedida != 'unid.')
            ? det.unidadMedida
            : (mat?.unidadMedida ?? 'unid.');
        final key = '${idMat}_${nombre}_$unidad';

        if (acumulador.containsKey(key)) {
          acumulador[key]!.cantidadTotal += det.cantidad;
        } else {
          acumulador[key] = MaterialConsolidado(
            idMaterial: idMat,
            codigo: codigo,
            nombre: nombre,
            unidadMedida: unidad,
            cantidadTotal: det.cantidad,
          );
        }
      }
    }

    final lista = acumulador.values.toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  // ============================================================
  // EXPORTAR EXCEL GLOBAL CON PESTAÑAS SEPARADAS POR PISO
  // ============================================================
  static Future<String> exportarMultiplesPisosExcel({
    required Map<String, List<SolicitudModel>> solicitudesPorPiso,
    String? nombreObra,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    bool primeraHoja = true;

    for (final entry in solicitudesPorPiso.entries) {
      final nombrePiso = entry.key;
      final listaSolicitudes = entry.value;

      String sheetName = nombrePiso.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
      if (sheetName.length > 30) {
        sheetName = sheetName.substring(0, 30);
      }
      if (sheetName.isEmpty) {
        sheetName = 'Piso';
      }

      if (primeraHoja) {
        excel.rename(defaultSheet, sheetName);
        primeraHoja = false;
      }

      final sheet = excel[sheetName];
      _llenarHojaPiso(
        sheet: sheet,
        nombrePiso: nombrePiso,
        solicitudes: listaSolicitudes,
        nombreObra: nombreObra,
      );
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo codificar el archivo Excel.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final now = DateUtilsBolivia.toBoliviaTime(DateTime.now());
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}${now.second}';
    final filePath = '${directory.path}/Control_Inventario_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(filePath);
    return filePath;
  }

  // ============================================================
  // EXPORTAR EXCEL DE UN PISO INDIVIDUAL CON MATERIALES CONSOLIDADOS
  // ============================================================
  static Future<String> exportarPisoIndividualExcel({
    required String nombrePiso,
    required List<SolicitudModel> solicitudes,
    String? nombreObra,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    String sheetName = nombrePiso.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
    if (sheetName.length > 30) sheetName = sheetName.substring(0, 30);
    if (sheetName.isEmpty) sheetName = 'Piso';

    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    _llenarHojaPiso(
      sheet: sheet,
      nombrePiso: nombrePiso,
      solicitudes: solicitudes,
      nombreObra: nombreObra,
    );

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo codificar el archivo Excel.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final now = DateUtilsBolivia.toBoliviaTime(DateTime.now());
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}';
    final cleanPiso = nombrePiso.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filePath = '${directory.path}/Control_Inventario_${cleanPiso}_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(filePath);
    return filePath;
  }

  // ============================================================
  // EXPORTAR EXCEL DE UNA SOLICITUD INDIVIDUAL
  // ============================================================
  static Future<String> exportarSolicitudACotizarExcel({
    required SolicitudModel solicitud,
    String? nombreObra,
  }) async {
    final nombrePiso = solicitud.piso?.nombre ?? 'Solicitud_${solicitud.idSolicitud}';
    final obra = nombreObra ?? solicitud.piso?.obra.nombre;
    return exportarPisoIndividualExcel(
      nombrePiso: nombrePiso,
      solicitudes: [solicitud],
      nombreObra: obra,
    );
  }

  // ============================================================
  // LLENAR HOJA DE CÁLCULO CON DISEÑO TEMA VERDE OSCURO (CONTROL DE INVENTARIO)
  // ============================================================
  static void _llenarHojaPiso({
    required Sheet sheet,
    required String nombrePiso,
    required List<SolicitudModel> solicitudes,
    String? nombreObra,
  }) {
    // Estilos inspirados en la plantilla verde oscuro institucional
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1E4D2B'),
    );

    final boldLabelStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
    );

    // Cabecera Verde Oscuro Bosque (#1E4D2B) con texto Blanco en negrita
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1E4D2B'),
      fontColorHex: ExcelColor.white,
    );

    final rowCenteredStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
    );

    final rowHighlightStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'), // Fondo verde claro suave
    );

    // 1. TÍTULO PRINCIPAL (Fila 2 - Similar a la imagen de referencia)
    sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue('CONTROL DE INVENTARIO Y COTIZACIÓN EN EXCEL');
    sheet.cell(CellIndex.indexByString('B2')).cellStyle = titleStyle;

    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Obra:');
    sheet.cell(CellIndex.indexByString('A4')).cellStyle = boldLabelStyle;
    sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(nombreObra ?? 'Obra General');

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Piso / Nivel:');
    sheet.cell(CellIndex.indexByString('A5')).cellStyle = boldLabelStyle;
    sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(nombrePiso);

    final nowFormatted = DateUtilsBolivia.formatBolivia(DateTime.now());
    sheet.cell(CellIndex.indexByString('D4')).value = TextCellValue('Fecha Emisión (BO):');
    sheet.cell(CellIndex.indexByString('D4')).cellStyle = boldLabelStyle;
    sheet.cell(CellIndex.indexByString('E4')).value = TextCellValue(nowFormatted);

    final idsSolicitudes = solicitudes.map((s) => '#${s.idSolicitud}').join(', ');
    sheet.cell(CellIndex.indexByString('D5')).value = TextCellValue('Solicitudes Incluidas:');
    sheet.cell(CellIndex.indexByString('D5')).cellStyle = boldLabelStyle;
    sheet.cell(CellIndex.indexByString('E5')).value = TextCellValue(idsSolicitudes);

    // 2. ENCABEZADOS DE LA TABLA (Fila 7)
    const headers = [
      'N°',
      'Código',
      'Producto / Material',
      'Unidad de Medida',
      'Cantidad Consolidada',
      'Precio Unitario (Bs.)',
      'Subtotal (Bs.)',
    ];

    const int headerRow = 6;

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // 3. LLENADO DE MATERIALES CONSOLIDADOS
    final materialesConsolidados = consolidarMateriales(solicitudes);

    for (int i = 0; i < materialesConsolidados.length; i++) {
      final item = materialesConsolidados[i];
      final rowIndex = headerRow + 1 + i;

      // N°
      final cellNum = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cellNum.value = IntCellValue(i + 1);
      cellNum.cellStyle = rowCenteredStyle;

      // Código
      final cellCod = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      cellCod.value = TextCellValue(item.codigo);
      cellCod.cellStyle = rowCenteredStyle;

      // Producto / Material
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(item.nombre);

      // Unidad de Medida
      final cellUnidad = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      cellUnidad.value = TextCellValue(item.unidadMedida);
      cellUnidad.cellStyle = rowCenteredStyle;

      // Cantidad Consolidada
      final cellCant = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      cellCant.value = IntCellValue(item.cantidadTotal);
      cellCant.cellStyle = rowHighlightStyle;

      // Espacios en blanco para Precio Unitario y Subtotal
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue('');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue('');
    }

    // Ajuste de anchos de columna
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 38);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 22);
    sheet.setColumnWidth(5, 22);
    sheet.setColumnWidth(6, 18);
  }
}
