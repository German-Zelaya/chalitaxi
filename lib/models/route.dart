import 'package:latlong2/latlong.dart';

/// Modelo que representa una ruta calculada
class RouteInfo {
  final List<LatLng> points;
  final double distanceInMeters;
  final double durationInSeconds;
  final String? instructions;

  RouteInfo({
    required this.points,
    required this.distanceInMeters,
    required this.durationInSeconds,
    this.instructions,
  });

  /// Distancia formateada en kilómetros
  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Duración formateada en minutos
  String get formattedDuration {
    int minutes = (durationInSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours h $remainingMinutes min';
    }
  }

  /// Calcula la tarifa estimada basada en la distancia
  /// Usando las mismas tarifas del taxímetro:
  /// - Tarifa base para 1 adulto: 5 Bs
  /// - 1.5 Bs por metro adicional después de los primeros 3 metros
  double calculateEstimatedFare({int adults = 1, int children = 0}) {
    double baseFare = 5.0; // Primer adulto

    // Adultos adicionales
    if (adults > 1) {
      baseFare += (adults - 1) * 3.0;
    }

    // Niños
    baseFare += children * 2.0;

    // Tarifa por distancia
    if (distanceInMeters > 3) {
      double extraMeters = distanceInMeters - 3;
      baseFare += extraMeters * 1.5;
    }

    return baseFare;
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'distanceInMeters': distanceInMeters,
      'durationInSeconds': durationInSeconds,
      'instructions': instructions,
    };
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    List<LatLng> pointsList = [];
    if (json['points'] != null) {
      for (var point in json['points']) {
        pointsList.add(LatLng(point['lat'], point['lng']));
      }
    }

    return RouteInfo(
      points: pointsList,
      distanceInMeters: json['distanceInMeters'].toDouble(),
      durationInSeconds: json['durationInSeconds'].toDouble(),
      instructions: json['instructions'],
    );
  }
}
