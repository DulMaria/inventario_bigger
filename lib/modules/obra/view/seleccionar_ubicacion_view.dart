import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class SeleccionarUbicacionView extends StatefulWidget {
  const SeleccionarUbicacionView({super.key});

  @override
  State<SeleccionarUbicacionView> createState() =>
      _SeleccionarUbicacionViewState();
}

class _SeleccionarUbicacionViewState
    extends State<SeleccionarUbicacionView> {
  final MapController _mapController = MapController();

  // Ubicación inicial.
  // Después podemos hacer que empiece en la ubicación actual
  // del dispositivo.
  LatLng _ubicacion = const LatLng(
    -16.5000,
    -68.1500,
  );

  String _direccion = '';
  bool _cargandoDireccion = false;

  Future<void> _seleccionarUbicacion(LatLng ubicacion) async {
    setState(() {
      _ubicacion = ubicacion;
      _cargandoDireccion = true;
      _direccion = '';
    });

    try {
      final lugares = await placemarkFromCoordinates(
        ubicacion.latitude,
        ubicacion.longitude,
      );

      if (lugares.isNotEmpty) {
        final lugar = lugares.first;

        final partes = <String>[
          if ((lugar.street ?? '').isNotEmpty)
            lugar.street!,
          if ((lugar.subLocality ?? '').isNotEmpty)
            lugar.subLocality!,
          if ((lugar.locality ?? '').isNotEmpty)
            lugar.locality!,
          if ((lugar.administrativeArea ?? '').isNotEmpty)
            lugar.administrativeArea!,
        ];

        setState(() {
          _direccion = partes.join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _direccion = 'No se pudo obtener la dirección';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDireccion = false;
        });
      }
    }
  }

  void _confirmarUbicacion() {
    Navigator.pop(
      context,
      {
        'direccion': _direccion,
        'latitud': _ubicacion.latitude,
        'longitud': _ubicacion.longitude,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ubicacion,
              initialZoom: 15,
              onTap: (tapPosition, punto) {
                _seleccionarUbicacion(punto);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.inventario_bigger',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _ubicacion,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Panel inferior
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_cargandoDireccion)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _direccion.isEmpty
                            ? 'Toca el mapa para seleccionar'
                            : _direccion,
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _direccion.isEmpty ||
                                    _cargandoDireccion
                                ? null
                                : _confirmarUbicacion,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Usar esta ubicación',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}