import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Modelo que representa un destino en Sucre
class Destination {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final IconData icon;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.icon,
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
      icon: Icons.location_on, // Ícono por defecto al cargar desde JSON
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
        icon: Icons.park, // Árbol/parque
      ),
      Destination(
        id: 'terminal_terrestre',
        name: 'Terminal de Buses',
        description: 'Terminal Terrestre de Sucre (Ostria Gutiérrez)',
        coordinates: LatLng(-19.03968, -65.24682),
        icon: Icons.directions_bus, // Bus
      ),
      Destination(
        id: 'mercado_central',
        name: 'Mercado Central',
        description: 'Mercado Central de Sucre',
        coordinates: LatLng(-19.0458, -65.2611),
        icon: Icons.shopping_basket, // Canasta de compras
      ),
      Destination(
        id: 'parque_bolivar',
        name: 'Parque Simón Bolívar',
        description: 'Parque Bolívar - Av. Venezuela / Km 7',
        coordinates: LatLng(-19.04268, -65.26268),
        icon: Icons.nature_people, // Naturaleza/personas
      ),
      Destination(
        id: 'aeropuerto',
        name: 'Aeropuerto Juana Azurduy',
        description: 'Aeropuerto Internacional de Sucre',
        coordinates: LatLng(-19.0071, -65.2887),
        icon: Icons.flight, // Avión
      ),
      Destination(
        id: 'universidad',
        name: 'Universidad San Francisco Xavier',
        description: 'USFX Central - Batalla Junín',
        coordinates: LatLng(-19.0475, -65.2605),
        icon: Icons.school, // Escuela/universidad
      ),
    ];
  }
}
