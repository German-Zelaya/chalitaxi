import 'package:latlong2/latlong.dart';

/// Modelo que representa un destino en Sucre
class Destination {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
    };
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coordinates: LatLng(json['latitude'], json['longitude']),
    );
  }
}

/// Destinos predefinidos populares en Sucre, Chuquisaca
class DestinationData {
  static List<Destination> getPopularDestinations() {
    return [
      Destination(
        id: 'plaza_25_mayo',
        name: 'Plaza 25 de Mayo',
        description: 'Plaza principal de Sucre',
        coordinates: LatLng(-19.0489, -65.2593),
      ),
      Destination(
        id: 'terminal_terrestre',
        name: 'Terminal de Buses',
        description: 'Terminal Terrestre de Sucre',
        coordinates: LatLng(-19.0316, -65.2892),
      ),
      Destination(
        id: 'mercado_central',
        name: 'Mercado Central',
        description: 'Mercado Central de Sucre',
        coordinates: LatLng(-19.0458, -65.2611),
      ),
      Destination(
        id: 'parque_bolivar',
        name: 'Parque Simón Bolívar',
        description: 'Parque Bolívar',
        coordinates: LatLng(-19.0430, -65.2570),
      ),
      Destination(
        id: 'aeropuerto',
        name: 'Aeropuerto Alcantarí',
        description: 'Aeropuerto Internacional de Sucre',
        coordinates: LatLng(-19.0071, -65.2887),
      ),
      Destination(
        id: 'universidad',
        name: 'Universidad San Francisco Xavier',
        description: 'Universidad Mayor Real y Pontificia',
        coordinates: LatLng(-19.0525, -65.2580),
      ),
    ];
  }
}
