import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../models/route.dart';
import '../services/route_service.dart';

/// Pantalla que muestra el mapa con la ruta recomendada
class RouteMapScreen extends StatefulWidget {
  final Position currentPosition;
  final Destination destination;

  const RouteMapScreen({
    super.key,
    required this.currentPosition,
    required this.destination,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final RouteService _routeService = RouteService();
  RouteInfo? _route;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final start = LatLng(
        widget.currentPosition.latitude,
        widget.currentPosition.longitude,
      );
      final end = widget.destination.coordinates;

      final route = await _routeService.getRoute(start, end);

      if (route == null) {
        setState(() {
          _errorMessage = 'No se pudo calcular la ruta';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _route = route;
        _isLoading = false;
      });

      // Ajustar el mapa para mostrar toda la ruta
      _fitBounds();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _fitBounds() {
    if (_route == null || _route!.points.isEmpty) return;

    // Calcular los límites de la ruta
    double minLat = _route!.points.first.latitude;
    double maxLat = _route!.points.first.latitude;
    double minLng = _route!.points.first.longitude;
    double maxLng = _route!.points.first.longitude;

    for (var point in _route!.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Agregar padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Esperar un frame para que el mapa esté renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ruta Recomendada',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Información del destino
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border(
                bottom: BorderSide(color: Colors.red[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_route != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(
                        icon: Icons.straighten,
                        label: 'Distancia',
                        value: _route!.formattedDistance,
                      ),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: 'Tiempo',
                        value: _route!.formattedDuration,
                      ),
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: 'Tarifa est.',
                        value: 'Bs. ${_route!.calculateEstimatedFare().toStringAsFixed(1)}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Calculando ruta...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            widget.currentPosition.latitude,
                            widget.currentPosition.longitude,
                          ),
                          initialZoom: 13,
                          minZoom: 10,
                          maxZoom: 18,
                        ),
                        children: [
                          // Capa de tiles de OpenStreetMap
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.chalitaxi',
                            maxZoom: 19,
                          ),

                          // Línea de la ruta
                          if (_route != null && _route!.points.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _route!.points,
                                  strokeWidth: 5.0,
                                  color: Colors.blue,
                                  borderStrokeWidth: 2.0,
                                  borderColor: Colors.blue[900]!,
                                ),
                              ],
                            ),

                          // Marcadores
                          MarkerLayer(
                            markers: [
                              // Marcador de inicio (ubicación actual)
                              Marker(
                                point: LatLng(
                                  widget.currentPosition.latitude,
                                  widget.currentPosition.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                              // Marcador de destino
                              Marker(
                                point: widget.destination.coordinates,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red[600],
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
          ),

          // Botón de acción
          if (_route != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Iniciar Viaje',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget para mostrar información en chips
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.red[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
      ],
    );
  }
}
