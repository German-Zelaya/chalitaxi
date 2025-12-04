import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resultado de una búsqueda de geocodificación
class GeocodingResult {
  final String displayName;
  final LatLng coordinates;
  final String type;

  GeocodingResult({
    required this.displayName,
    required this.coordinates,
    required this.type,
  });
}

/// Servicio de geocodificación usando Nominatim (API gratuita de OpenStreetMap)
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Busca lugares por texto
  ///
  /// [query] - Texto a buscar (ej: "Hospital Santa Bárbara" o "Calle Arenales")
  /// [limitToSucre] - Si es true, limita la búsqueda a Sucre, Bolivia
  ///
  /// Retorna una lista de resultados encontrados
  Future<List<GeocodingResult>> searchPlace(
    String query, {
    bool limitToSucre = true,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Construir query con Sucre, Bolivia para mejorar resultados
      String searchQuery = query;
      if (limitToSucre) {
        searchQuery = '$query, Sucre, Chuquisaca, Bolivia';
      }

      final url = Uri.parse(
        '$_baseUrl/search?'
        'q=${Uri.encodeComponent(searchQuery)}&'
        'format=json&'
        'limit=5&'
        'addressdetails=1&'
        'countrycodes=bo', // Solo Bolivia
      );

      print('Buscando: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ChaliTaxi/1.0', // Nominatim requiere User-Agent
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          return [];
        }

        List<GeocodingResult> results = [];
        for (var item in data) {
          results.add(GeocodingResult(
            displayName: item['display_name'] ?? 'Lugar sin nombre',
            coordinates: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
            type: item['type'] ?? 'unknown',
          ));
        }

        print('Encontrados ${results.length} resultados');
        return results;
      } else {
        print('Error HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error en búsqueda: $e');
      return [];
    }
  }

  /// Obtiene el nombre de un lugar a partir de coordenadas (geocodificación inversa)
  ///
  /// [coordinates] - Coordenadas GPS del lugar
  ///
  /// Retorna el nombre del lugar o null si hay error
  Future<String?> getPlaceName(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?'
        'lat=${coordinates.latitude}&'
        'lon=${coordinates.longitude}&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ChaliTaxi/1.0',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error en geocodificación inversa: $e');
      return null;
    }
  }
}
