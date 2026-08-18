import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SeleccionarUbicacionView extends StatefulWidget {
  /// Coordenadas existentes de la obra.
  ///
  /// Se utilizan cuando estamos EDITANDO una obra.
  /// Si son null, se intenta obtener la ubicación actual del dispositivo.
  final double? latitudInicial;
  final double? longitudInicial;

  const SeleccionarUbicacionView({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
  });

  @override
  State<SeleccionarUbicacionView> createState() =>
      _SeleccionarUbicacionViewState();
}

class _SeleccionarUbicacionViewState extends State<SeleccionarUbicacionView> {
  final MapController _mapController = MapController();

  final TextEditingController _busquedaController = TextEditingController();

  Timer? _debounce;

  // Ubicación de respaldo.
  // Se utiliza si no se puede obtener la ubicación del dispositivo.
  LatLng _ubicacion = const LatLng(-16.5000, -68.1500);

  String _direccion = '';

  bool _cargandoDireccion = false;
  bool _buscando = false;
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();

    _inicializarUbicacion();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaController.dispose();

    super.dispose();
  }

  // ============================================================
  // INICIALIZAR UBICACIÓN
  // ============================================================

  Future<void> _inicializarUbicacion() async {
    /*
     * CASO 1:
     * Estamos editando una obra que ya tiene coordenadas.
     *
     * Utilizamos directamente esas coordenadas.
     */
    if (widget.latitudInicial != null && widget.longitudInicial != null) {
      final ubicacionGuardada = LatLng(
        widget.latitudInicial!,
        widget.longitudInicial!,
      );

      setState(() {
        _ubicacion = ubicacionGuardada;
      });

      await _obtenerDireccion(ubicacionGuardada);

      return;
    }

    /*
     * CASO 2:
     * Estamos creando una obra.
     *
     * Intentamos obtener la ubicación actual del gerente.
     */
    await _obtenerUbicacionActual(moverMapa: false);
  }

  // ============================================================
  // OBTENER UBICACIÓN ACTUAL
  // ============================================================

  Future<void> _obtenerUbicacionActual({bool moverMapa = true}) async {
    if (!mounted) return;

    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa la ubicación del dispositivo para '
              'obtener tu posición actual.',
            ),
          ),
        );

        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se concedió permiso para acceder a la ubicación.',
            ),
          ),
        );

        return;
      }

      if (permiso == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El permiso de ubicación está bloqueado. '
              'Actívalo desde los ajustes del dispositivo.',
            ),
          ),
        );

        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final nuevaUbicacion = LatLng(posicion.latitude, posicion.longitude);

      if (!mounted) return;

      setState(() {
        _ubicacion = nuevaUbicacion;
      });

      if (moverMapa) {
        _mapController.move(nuevaUbicacion, 17);
      }

      await _obtenerDireccion(nuevaUbicacion);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación actual.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }

  // ============================================================
  // OBTENER DIRECCIÓN
  // ============================================================

  Future<void> _obtenerDireccion(LatLng ubicacion) async {
    if (!mounted) return;

    setState(() {
      _cargandoDireccion = true;
      _direccion = '';
    });

    try {
      final lugares = await placemarkFromCoordinates(
        ubicacion.latitude,
        ubicacion.longitude,
      );

      if (!mounted) return;

      if (lugares.isEmpty) {
        setState(() {
          _direccion = 'No se encontró una dirección para este punto.';
        });

        return;
      }

      final lugar = lugares.first;

      final partes = <String>[
        if ((lugar.street ?? '').trim().isNotEmpty) lugar.street!.trim(),

        if ((lugar.subLocality ?? '').trim().isNotEmpty)
          lugar.subLocality!.trim(),

        if ((lugar.locality ?? '').trim().isNotEmpty) lugar.locality!.trim(),

        if ((lugar.administrativeArea ?? '').trim().isNotEmpty)
          lugar.administrativeArea!.trim(),

        if ((lugar.country ?? '').trim().isNotEmpty) lugar.country!.trim(),
      ];

      setState(() {
        _direccion = partes.isEmpty
            ? 'Dirección no disponible'
            : partes.join(', ');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _direccion = 'No se pudo obtener la dirección.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDireccion = false;
        });
      }
    }
  }

  // ============================================================
  // ACTUALIZAR UBICACIÓN
  // ============================================================

  void _actualizarUbicacion(LatLng nuevaUbicacion) {
    if (!mounted) return;

    setState(() {
      _ubicacion = nuevaUbicacion;
      _direccion = '';
    });

    /*
     * Esperamos un poco antes de consultar la dirección.
     *
     * Esto evita hacer muchas peticiones si el gerente
     * mueve el mapa rápidamente.
     */
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _obtenerDireccion(nuevaUbicacion);
    });
  }

  // ============================================================
  // BUSCAR LUGAR
  // ============================================================

  Future<void> _buscarLugar() async {
    final texto = _busquedaController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _buscando = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(texto)}'
        '&format=json'
        '&limit=5'
        '&countrycodes=bo',
      );

      final respuesta = await http.get(
        url,
        headers: {'User-Agent': 'inventario_bigger/1.0'},
      );

      if (respuesta.statusCode != 200) {
        throw Exception('No se pudo realizar la búsqueda');
      }

      final List resultados = jsonDecode(respuesta.body);

      if (resultados.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el lugar buscado.')),
        );

        return;
      }

      if (!mounted) return;

      await _mostrarResultadosBusqueda(resultados);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo realizar la búsqueda.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
        });
      }
    }
  }

  // ============================================================
  // MOSTRAR RESULTADOS DE BÚSQUEDA
  // ============================================================

  Future<void> _mostrarResultadosBusqueda(List resultados) async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecciona un lugar de referencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      final resultado = resultados[index];

                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(
                          resultado['display_name']?.toString() ??
                              'Lugar sin nombre',
                        ),
                        onTap: () {
                          Navigator.pop(context, {
                            'lat': double.parse(resultado['lat'].toString()),
                            'lon': double.parse(resultado['lon'].toString()),
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    final nuevaUbicacion = LatLng(resultado['lat'], resultado['lon']);

    _mapController.move(nuevaUbicacion, 17);

    _actualizarUbicacion(nuevaUbicacion);
  }

  // ============================================================
  // CONFIRMAR UBICACIÓN
  // ============================================================

  void _confirmarUbicacion() {
    if (_direccion.isEmpty || _cargandoDireccion) {
      return;
    }

    Navigator.pop(context, {
      'direccion': _direccion,
      'latitud': _ubicacion.latitude,
      'longitud': _ubicacion.longitude,
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),

      body: Stack(
        children: [
          // ======================================================
          // MAPA
          // ======================================================

          FlutterMap(
            mapController: _mapController,

            options: MapOptions(
              initialCenter: _ubicacion,
              initialZoom: 15,

              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _actualizarUbicacion(event.camera.center);
                }
              },
            ),

            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName: 'com.example.inventario_bigger',
              ),
            ],
          ),

          // ======================================================
          // MARCADOR CENTRAL
          // ======================================================
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_pin, size: 55, color: Colors.red),
            ),
          ),

          // ======================================================
          // BUSCADOR
          // ======================================================
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(12),

              child: TextField(
                controller: _busquedaController,

                textInputAction: TextInputAction.search,

                onSubmitted: (_) {
                  _buscarLugar();
                },

                decoration: InputDecoration(
                  hintText: 'Buscar un lugar o dirección',

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: _buscando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _buscarLugar,
                        ),

                  filled: true,

                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // BOTÓN MI UBICACIÓN
          // ======================================================
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'mi_ubicacion',

              onPressed: _obteniendoUbicacion
                  ? null
                  : () {
                      _obtenerUbicacionActual(moverMapa: true);
                    },

              child: _obteniendoUbicacion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // ======================================================
          // PANEL INFERIOR
          // ======================================================
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 5,

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_cargandoDireccion)
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        _direccion.isEmpty
                            ? 'Mueve el mapa para seleccionar la ubicación'
                            : _direccion,
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed: _direccion.isEmpty || _cargandoDireccion
                            ? null
                            : _confirmarUbicacion,

                        icon: const Icon(Icons.check),

                        label: const Text('Usar esta ubicación'),
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
