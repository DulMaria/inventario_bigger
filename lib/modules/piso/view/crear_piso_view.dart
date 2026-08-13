import 'package:flutter/material.dart';

import '../controller/piso_controller.dart';

class CrearPisoView extends StatefulWidget {
  final int idObra;

  const CrearPisoView({
    super.key,
    required this.idObra,
  });

  @override
  State<CrearPisoView> createState() => _CrearPisoViewState();
}

class _CrearPisoViewState extends State<CrearPisoView> {
  final PisoController _pisoController = PisoController();

  final TextEditingController _nombreController =
      TextEditingController();

  String _tipoSeleccionado = 'Piso normal';

  bool _cargando = true;
  bool _guardando = false;

  final List<String> _tipos = [
    'Piso normal',
    'Sótano',
    'Terraza',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _generarNombre();
  }

  Future<void> _generarNombre() async {
    try {
      final pisos = await _pisoController.obtenerPisos(
        widget.idObra,
      );

      final nombres = pisos
          .map(
            (piso) => (piso.nombre ?? '').trim().toLowerCase(),
          )
          .toSet();

      final numero = _siguienteNumero(
        nombres,
        'piso',
      );

      if (!mounted) return;

      setState(() {
        _nombreController.text = 'Piso $numero';
        _cargando = false;
      });

      _seleccionarTexto();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _nombreController.text = 'Piso 1';
        _cargando = false;
      });

      _seleccionarTexto();
    }
  }

  int _siguienteNumero(
    Set<String> nombres,
    String tipo,
  ) {
    int mayor = 0;

    final regex = RegExp(
      '^${RegExp.escape(tipo)}\\s+(\\d+)\$',
      caseSensitive: false,
    );

    for (final nombre in nombres) {
      final coincidencia = regex.firstMatch(nombre);

      if (coincidencia != null) {
        final numero = int.tryParse(
          coincidencia.group(1)!,
        );

        if (numero != null && numero > mayor) {
          mayor = numero;
        }
      }
    }

    return mayor + 1;
  }

  Future<void> _cambiarTipo(String tipo) async {
    setState(() {
      _tipoSeleccionado = tipo;
      _cargando = true;
    });

    try {
      final pisos = await _pisoController.obtenerPisos(
        widget.idObra,
      );

      final nombres = pisos
          .map(
            (piso) => (piso.nombre ?? '').trim().toLowerCase(),
          )
          .toSet();

      String nombre;

      if (tipo == 'Piso normal') {
        final numero = _siguienteNumero(
          nombres,
          'piso',
        );

        nombre = 'Piso $numero';
      } else if (tipo == 'Sótano') {
        final numero = _siguienteNumero(
          nombres,
          'sótano',
        );

        nombre = 'Sótano $numero';
      } else if (tipo == 'Terraza') {
        final numero = _siguienteNumero(
          nombres,
          'terraza',
        );

        nombre = 'Terraza $numero';
      } else {
        nombre = '';
      }

      if (!mounted) return;

      setState(() {
        _nombreController.text = nombre;
        _cargando = false;
      });

      _seleccionarTexto();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });
    }
  }

  void _seleccionarTexto() {
    _nombreController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nombreController.text.length,
    );
  }

  Future<void> _crearPiso() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre del piso'),
        ),
      );
      return;
    }

    if (nombre.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre no puede superar los 50 caracteres',
          ),
        ),
      );
      return;
    }

    if (nombre.replaceAll(' ', '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no es válido'),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final pisos = await _pisoController.obtenerPisos(
        widget.idObra,
      );

      final existe = pisos.any(
        (piso) =>
            (piso.nombre ?? '').trim().toLowerCase() ==
            nombre.toLowerCase(),
      );

      if (existe) {
        if (!mounted) return;

        setState(() {
          _guardando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ya existe un piso llamado "$nombre"',
            ),
          ),
        );

        return;
      }

      await _pisoController.crearPiso(
        idObra: widget.idObra,
        nombre: nombre,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear el piso: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear piso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de piso',
                      border: OutlineInputBorder(),
                    ),
                    items: _tipos.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            if (valor != null) {
                              _cambiarTipo(valor);
                            }
                          },
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _nombreController,
                    maxLength: 50,
                    enabled: _tipoSeleccionado == 'Otro',
                    decoration: const InputDecoration(
                      labelText: 'Nombre del piso',
                      hintText: 'Ej. Mezanine, Azotea...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando
                          ? null
                          : _crearPiso,
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(),
                            )
                          : const Text('Crear piso'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}