import 'package:flutter/material.dart';

import '../../../models/material_model.dart';
import '../controller/material_controller.dart';
import '../../solicitud/controller/solicitud_controller.dart';

class MaterialesView extends StatefulWidget {
  final int idObra;
  final int idPiso;
  final int idUsuario;

  const MaterialesView({
    super.key,
    required this.idObra,
    required this.idPiso,
    required this.idUsuario,
  });

  @override
  State<MaterialesView> createState() => _MaterialesViewState();
}

class _MaterialesViewState extends State<MaterialesView> {
  final MaterialController _controller = MaterialController();

  final List<Map<String, dynamic>> _solicitud = [];

  final SolicitudController _solicitudController = SolicitudController();

  bool _enviandoSolicitud = false;

  List<MaterialModel> _materiales = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMateriales();
  }

  Future<void> _cargarMateriales() async {
    try {
      final materiales = await _controller.obtenerMateriales();

      if (!mounted) return;

      setState(() {
        _materiales = materiales;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _mostrarAgregarMaterial() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AgregarMaterialDialog(controller: _controller);
      },
    );

    if (!mounted || resultado == null) return;

    final MaterialModel material = resultado['material'];
    final int cantidad = resultado['cantidad'];

    final yaAgregado = _solicitud.any(
      (item) => item['id_material'] == material.idMaterial,
    );

    if (yaAgregado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material ya está en la solicitud.')),
      );
      return;
    }

    setState(() {
      _solicitud.add({
        'id_material': material.idMaterial,
        'material': material.nombre,
        'codigo': material.codigo,
        'cantidad': cantidad,
      });

      final existeEnLista = _materiales.any(
        (item) => item.idMaterial == material.idMaterial,
      );

      if (!existeEnLista) {
        _materiales.add(material);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${material.nombre} añadido a la solicitud.')),
    );
  }

  Future<void> _editarMaterial(int index) async {
    final item = _solicitud[index];

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _EditarMaterialDialog(
          controller: _controller,
          materialActual: item['material'].toString(),
          cantidadActual: item['cantidad'] as int,
        );
      },
    );

    if (!mounted || resultado == null) return;

    final MaterialModel material = resultado['material'];
    final int cantidad = resultado['cantidad'];

    final yaExiste = _solicitud.asMap().entries.any((entry) {
      return entry.key != index &&
          entry.value['id_material'] == material.idMaterial;
    });

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este material ya está agregado en la lista'),
        ),
      );
      return;
    }

    setState(() {
      _solicitud[index] = {
        'id_material': material.idMaterial,
        'material': material.nombre,
        'codigo': material.codigo,
        'cantidad': cantidad,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${material.nombre} actualizado correctamente')),
    );
  }

  void _eliminarMaterial(int index) {
    setState(() {
      _solicitud.removeAt(index);
    });
  }

  Future<void> _enviarSolicitud() async {
    if (_solicitud.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un material antes de enviar.'),
        ),
      );
      return;
    }

    setState(() {
      _enviandoSolicitud = true;
    });

    try {
      await _solicitudController.crearSolicitud(
        idPiso: widget.idPiso,
        idUsuario: widget.idUsuario,
        materiales: _solicitud,
      );

      if (!mounted) return;

      setState(() {
        _solicitud.clear();
        _enviandoSolicitud = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviandoSolicitud = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: const Text('Materiales'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Materiales del piso',
                    style: TextStyle(fontSize: 17, color: Color(0xFF7C8A93)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Piso ${widget.idPiso}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A32),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Materiales solicitados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2A32),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _mostrarAgregarMaterial,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2FA9E0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _solicitud.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 70,
                                  color: Color(0xFFB7C5CC),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'No hay materiales solicitados',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7C8A93),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Añade los materiales que necesitas para este piso.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9AA7AE),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _solicitud.length,
                            itemBuilder: (context, index) {
                              final item = _solicitud[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1F3FC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF2FA9E0),
                                    ),
                                  ),
                                  title: Text(
                                    item['material'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['codigo']} • Cantidad solicitada: ${item['cantidad']}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (valor) {
                                      if (valor == 'editar') {
                                        _editarMaterial(index);
                                      }

                                      if (valor == 'eliminar') {
                                        _eliminarMaterial(index);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'editar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined),
                                            SizedBox(width: 10),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'eliminar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline),
                                            SizedBox(width: 10),
                                            Text('Eliminar'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_solicitud.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviandoSolicitud ? null : _enviarSolicitud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2FA9E0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Enviar solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _AgregarMaterialDialog extends StatefulWidget {
  final MaterialController controller;

  const _AgregarMaterialDialog({required this.controller});

  @override
  State<_AgregarMaterialDialog> createState() => _AgregarMaterialDialogState();
}

class _EditarMaterialDialog extends StatefulWidget {
  final MaterialController controller;
  final String materialActual;
  final int cantidadActual;

  const _EditarMaterialDialog({
    required this.controller,
    required this.materialActual,
    required this.cantidadActual,
  });

  @override
  State<_EditarMaterialDialog> createState() => _EditarMaterialDialogState();
}

class _EditarMaterialDialogState extends State<_EditarMaterialDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _cantidadController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.materialActual);

    _cantidadController = TextEditingController(
      text: widget.cantidadActual.toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Ingresa el nombre del material.');
      return;
    }

    if (cantidadTexto.isEmpty) {
      _mostrarError('Ingresa la cantidad.');
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);

    if (cantidad == null || cantidad <= 0) {
      _mostrarError('La cantidad debe ser un número mayor a 0.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      MaterialModel? material;

      material = await widget.controller.buscarMaterial(nombre);

      material ??= await widget.controller.crearMaterial(nombre);

      if (!mounted) return;

      Navigator.of(context).pop({'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar material'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Material',
                hintText: 'Ej. Clavo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cantidadController,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej. 20',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2FA9E0),
            foregroundColor: Colors.white,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _AgregarMaterialDialogState extends State<_AgregarMaterialDialog> {
  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _cantidadController = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Ingresa el nombre del material.');
      return;
    }

    if (cantidadTexto.isEmpty) {
      _mostrarError('Ingresa la cantidad.');
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);

    if (cantidad == null || cantidad <= 0) {
      _mostrarError('La cantidad debe ser un número mayor a 0.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      MaterialModel? material;

      material = await widget.controller.buscarMaterial(nombre);

      material ??= await widget.controller.crearMaterial(nombre);

      if (!mounted) return;

      Navigator.of(context).pop({'material': material, 'cantidad': cantidad});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir material'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Material',
                hintText: 'Ej. Clavo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cantidadController,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad a solicitar',
                hintText: 'Ej. 20',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2FA9E0),
            foregroundColor: Colors.white,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Añadir'),
        ),
      ],
    );
  }
}
