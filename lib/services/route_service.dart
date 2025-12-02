import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route.dart';

/// Servicio para obtener rutas usando OSRM (Open Source Routing Machine)
/// API completamente gratuita
class RouteService {
  // Servidor público de OSRM (gratuito)
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Obtiene una ruta entre dos puntos
  ///
  /// [start] - Punto de inicio (coordenadas actuales)
  /// [end] - Punto de destino
  ///
  /// Retorna un [RouteInfo] con la ruta calculada o null si hay error
  Future<RouteInfo?> getRoute(LatLng start, LatLng end) async {
    try {
      // Construir URL para OSRM
      // Formato: /route/v1/driving/{longitude,latitude;longitude,latitude}
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?'
        'overview=full&geometries=geojson&steps=true',
      );

      print('Solicitando ruta a OSRM: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al obtener ruta');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok') {
          print('Error en respuesta OSRM: ${data['code']}');
          return null;
        }

        if (data['routes'] == null || data['routes'].isEmpty) {
          print('No se encontraron rutas');
          return null;
        }

        final route = data['routes'][0];
        final geometry = route['geometry'];
        final distance = route['distance'].toDouble(); // en metros
        final duration = route['duration'].toDouble(); // en segundos

        // Convertir geometría GeoJSON a lista de LatLng
        List<LatLng> points = [];
        if (geometry['coordinates'] != null) {
          for (var coord in geometry['coordinates']) {
            // GeoJSON usa [longitude, latitude]
            points.add(LatLng(coord[1], coord[0]));
          }
        }

        // Extraer instrucciones si están disponibles
        String? instructions;
        if (route['legs'] != null && route['legs'].isNotEmpty) {
          final steps = route['legs'][0]['steps'];
          if (steps != null) {
            List<String> stepInstructions = [];
            for (var step in steps) {
              if (step['maneuver'] != null && step['maneuver']['type'] != null) {
                stepInstructions.add(step['maneuver']['type']);
              }
            }
            instructions = stepInstructions.join(', ');
          }
        }

        print('Ruta obtenida: ${distance}m, ${duration}s, ${points.length} puntos');

        return RouteInfo(
          points: points,
          distanceInMeters: distance,
          durationInSeconds: duration,
          instructions: instructions,
        );
      } else {
        print('Error HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener ruta: $e');
      return null;
    }
  }

  /// Obtiene múltiples rutas alternativas (si están disponibles)
  Future<List<RouteInfo>> getAlternativeRoutes(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?'
        'overview=full&geometries=geojson&steps=true&alternatives=true&number=3',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok' || data['routes'] == null) {
          return [];
        }

        List<RouteInfo> routes = [];
        for (var route in data['routes']) {
          final geometry = route['geometry'];
          final distance = route['distance'].toDouble();
          final duration = route['duration'].toDouble();

          List<LatLng> points = [];
          if (geometry['coordinates'] != null) {
            for (var coord in geometry['coordinates']) {
              points.add(LatLng(coord[1], coord[0]));
            }
          }

          routes.add(RouteInfo(
            points: points,
            distanceInMeters: distance,
            durationInSeconds: duration,
          ));
        }

        return routes;
      } else {
        return [];
      }
    } catch (e) {
      print('Error al obtener rutas alternativas: $e');
      return [];
    }
  }
}
