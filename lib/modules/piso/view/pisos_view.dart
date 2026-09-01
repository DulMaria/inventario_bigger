import 'package:flutter/material.dart';

import '../../../models/obra_model.dart';
import '../../../models/piso_model.dart';

import '../controller/piso_controller.dart';
import 'crear_piso_view.dart';
import 'editar_piso_view.dart';

class PisosView extends StatefulWidget {
  final ObraModel obra;

  const PisosView({super.key, required this.obra});

  @override
  State<PisosView> createState() => _PisosViewState();
}

class _PisosViewState extends State<PisosView> {
  final PisoController _pisoController = PisoController();
  List<PisoModel> _pisos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> _cargarDatos() async {
    if (mounted) {
      setState(() {
        _cargando = true;
      });
    }

    try {
      final pisos = await _pisoController.obtenerPisos(widget.obra.idObra);

      if (!mounted) return;

      setState(() {
        _pisos = pisos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar los datos: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CREAR PISO
  // ============================================================

  Future<void> _irACrearPiso() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPisoView(idObra: widget.obra.idObra),
      ),
    );

    if (resultado == true && mounted) {
      await _cargarDatos();
    }
  }

  // ============================================================
  // EDITAR PISO
  // ============================================================

  Future<void> _irAEditarPiso(PisoModel piso) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarPisoView(piso: piso)),
    );

    if (resultado == true && mounted) {
      await _cargarDatos();
    }
  }

  // ============================================================
  // TEXTO Y COLORES
  // ============================================================

  String _textoTipo(String tipo, int numero) {
    switch (tipo) {
      case 'NORMAL':
        return 'Piso / Departamento • Nivel $numero';
      case 'SOTANO':
        return 'Sótano • Nivel $numero';
      case 'TERRAZA':
        return 'Terraza • Nivel $numero';
      case 'ESPECIAL':
        return 'Especial • Nivel $numero';
      default:
        return '$tipo • Nivel $numero';
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'NO INICIADO':
        return Colors.grey.shade600;
      case 'OBRA BRUTA':
        return Colors.orange.shade800;
      case 'OBRA FINA':
        return Colors.blue.shade700;
      case 'FINALIZADO':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Color _fondoEstado(String estado) {
    switch (estado) {
      case 'NO INICIADO':
        return Colors.grey.shade200;
      case 'OBRA BRUTA':
        return Colors.orange.shade50;
      case 'OBRA FINA':
        return Colors.blue.shade50;
      case 'FINALIZADO':
        return Colors.green.shade50;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'TERRAZA':
        return Icons.deck_outlined;
      case 'SOTANO':
        return Icons.foundation_outlined;
      default:
        return Icons.apartment_outlined;
    }
  }

  // ============================================================
  // TARJETA DE PISO
  // ============================================================

  Widget _tarjetaPiso(PisoModel piso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE1F3FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconoTipo(piso.tipoPiso), color: const Color(0xFF2FA9E0)),
        ),
        title: Text(
          piso.nombre ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _textoTipo(piso.tipoPiso, piso.numeroPiso),
              style: const TextStyle(color: Color(0xFF5F6B73), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _fondoEstado(piso.estadoObra),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _colorEstado(piso.estadoObra).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                piso.estadoObra,
                style: TextStyle(
                  color: _colorEstado(piso.estadoObra),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF2FA9E0)),
          tooltip: 'Editar piso',
          onPressed: () => _irAEditarPiso(piso),
        ),
        onTap: () => _irAEditarPiso(piso),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        title: Text('Pisos - ${widget.obra.nombre}'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : _irACrearPiso,
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Piso'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pisos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 72,
                          color: Color(0xFFB7C5CC),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin pisos registrados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registra los niveles de la obra (sótanos, pisos o terrazas).',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7C8A93)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _irACrearPiso,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear primer piso'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2FA9E0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _pisos.length,
                    itemBuilder: (context, index) {
                      return _tarjetaPiso(_pisos[index]);
                    },
                  ),
                ),
    );
  }
}
