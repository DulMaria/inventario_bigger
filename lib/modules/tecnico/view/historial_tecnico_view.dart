import 'package:flutter/material.dart';

import '../../../models/solicitud_model.dart';
import '../../../models/solicitud_obrero_model.dart';
import '../../solicitud/controller/solicitud_controller.dart';
import '../../solicitud/controller/solicitud_obrero_controller.dart';

class HistorialTecnicoView extends StatefulWidget {
  final int idObra;

  const HistorialTecnicoView({super.key, required this.idObra});

  @override
  State<HistorialTecnicoView> createState() => _HistorialTecnicoViewState();
}

class _HistorialTecnicoViewState extends State<HistorialTecnicoView>
    with SingleTickerProviderStateMixin {
  final SolicitudObreroController _obreroController =
      SolicitudObreroController();
  final SolicitudController _comprasController = SolicitudController();

  List<SolicitudObreroModel> _solicitudesObreros = [];
  List<SolicitudModel> _pedidosCompras = [];
  bool _cargando = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarHistorial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
    });

    try {
      final listObreros = await _obreroController.obtenerTodas(widget.idObra);
      final listCompras = await _comprasController.obtenerTodas(widget.idObra);

      if (!mounted) return;

      setState(() {
        _solicitudesObreros = listObreros;
        _pedidosCompras = listCompras;
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
            'Error al cargar historial: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return Colors.orange.shade800;
      case 'APROBADA':
        return Colors.green.shade700;
      case 'RECHAZADA':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Color _fondoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return Colors.orange.shade50;
      case 'APROBADA':
        return Colors.green.shade50;
      case 'RECHAZADA':
        return Colors.red.shade50;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
      case 'PENDIENTE_REVISION':
        return 'Pendiente';
      case 'APROBADA':
        return 'Aprobada';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historial de la Obra'),
        backgroundColor: const Color(0xFF2FA9E0),
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.engineering, size: 20),
              text: 'De Obreros (${_solicitudesObreros.length})',
            ),
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              text: 'A Compras (${_pedidosCompras.length})',
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaObreros(),
                _buildListaCompras(),
              ],
            ),
    );
  }

  Widget _buildListaObreros() {
    if (_solicitudesObreros.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay solicitudes de obreros en esta obra.',
            style: TextStyle(color: Color(0xFF7C8A93), fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudesObreros.length,
        itemBuilder: (context, index) {
          final sol = _solicitudesObreros[index];
          final obrero = sol.usuario != null
              ? '${sol.usuario!.nombre} ${sol.usuario!.apellido}'
              : 'Obrero #${sol.idUsuario}';
          final piso = sol.piso?.etiquetaNivel ?? 'Piso';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                backgroundColor: _fondoEstado(sol.estado),
                child: Icon(
                  sol.estado == 'APROBADA'
                      ? Icons.check
                      : sol.estado == 'RECHAZADA'
                          ? Icons.close
                          : Icons.access_time,
                  color: _colorEstado(sol.estado),
                ),
              ),
              title: Text(
                '$obrero • $piso',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Estado: ${_textoEstado(sol.estado)} • ${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year} ${sol.fecha.hour.toString().padLeft(2, '0')}:${sol.fecha.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _colorEstado(sol.estado),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Text(
                        'Materiales solicitados:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...sol.detalles.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Color(0xFF2FA9E0),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(d.material?.nombre ?? 'Material'),
                              ),
                              Text(
                                'Cant: ${d.cantidad}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D7FAE),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (sol.observacion != null &&
                          sol.observacion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Observación: ${sol.observacion}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaCompras() {
    if (_pedidosCompras.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay pedidos enviados a compras en esta obra.',
            style: TextStyle(color: Color(0xFF7C8A93), fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidosCompras.length,
        itemBuilder: (context, index) {
          final sol = _pedidosCompras[index];
          final piso = sol.piso?.etiquetaNivel ?? 'Piso';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                backgroundColor: _fondoEstado(sol.estado),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: _colorEstado(sol.estado),
                ),
              ),
              title: Text(
                'Pedido para $piso',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Estado: ${_textoEstado(sol.estado)} • ${sol.fecha.day}/${sol.fecha.month}/${sol.fecha.year} ${sol.fecha.hour.toString().padLeft(2, '0')}:${sol.fecha.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _colorEstado(sol.estado),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Text(
                        'Materiales enviados a compras:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...sol.detalles.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Color(0xFF2FA9E0),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(d.material?.nombre ?? 'Material'),
                              ),
                              Text(
                                'Cant: ${d.cantidad}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D7FAE),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (sol.observacion != null &&
                          sol.observacion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Observación: ${sol.observacion}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
