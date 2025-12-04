import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Modelo para lugar conocido en la base de datos local
class LocalPlace {
  final String name;
  final String category;
  final LatLng coordinates;
  final List<String> searchTerms;

  LocalPlace({
    required this.name,
    required this.category,
    required this.coordinates,
    required this.searchTerms,
  });

  bool matches(String query) {
    String lowerQuery = query.toLowerCase();
    return searchTerms.any((term) => term.toLowerCase().contains(lowerQuery)) ||
           name.toLowerCase().contains(lowerQuery);
  }
}

/// Base de datos local de lugares conocidos en Sucre
class SucreLocalPlaces {
  static List<LocalPlace> getAllPlaces() {
    return [
      // HOSPITALES Y CLÍNICAS
      LocalPlace(
        name: 'Hospital Santa Bárbara',
        category: 'Hospital',
        coordinates: LatLng(-19.04479, -65.26356),
        searchTerms: ['hospital', 'santa barbara', 'santa bárbara', 'clinica', 'salud'],
      ),
      LocalPlace(
        name: 'Hospital San Pedro Claver',
        category: 'Hospital',
        coordinates: LatLng(-19.0425, -65.2615),
        searchTerms: ['hospital', 'san pedro claver', 'claver', 'salud'],
      ),
      LocalPlace(
        name: 'Hospital Gineco Obstétrico Jaime Sánchez Porcel',
        category: 'Hospital',
        coordinates: LatLng(-19.04531, -65.26830),
        searchTerms: ['hospital', 'gineco', 'obstetrico', 'ginecológico', 'maternidad', 'jaime sanchez', 'sanchez porcel'],
      ),
      LocalPlace(
        name: 'Clínica Los Pinos',
        category: 'Clínica',
        coordinates: LatLng(-19.0415, -65.2601),
        searchTerms: ['clinica', 'los pinos', 'pinos', 'salud'],
      ),
      LocalPlace(
        name: 'Clínica Sucre',
        category: 'Clínica',
        coordinates: LatLng(-19.0478, -65.2595),
        searchTerms: ['clinica', 'sucre', 'salud'],
      ),

      // MERCADOS
      LocalPlace(
        name: 'Mercado Central',
        category: 'Mercado',
        coordinates: LatLng(-19.0458, -65.2611),
        searchTerms: ['mercado', 'central', 'compras', 'verduras', 'frutas'],
      ),
      LocalPlace(
        name: 'Mercado Campesino',
        category: 'Mercado',
        coordinates: LatLng(-19.0442, -65.2625),
        searchTerms: ['mercado', 'campesino', 'compras', 'verduras'],
      ),
      LocalPlace(
        name: 'Mercado Negro',
        category: 'Mercado',
        coordinates: LatLng(-19.0465, -65.2605),
        searchTerms: ['mercado', 'negro', 'compras'],
      ),

      // UNIVERSIDADES Y EDUCACIÓN
      LocalPlace(
        name: 'Universidad San Francisco Xavier (Central)',
        category: 'Universidad',
        coordinates: LatLng(-19.0475, -65.2605),
        searchTerms: ['universidad', 'usfx', 'san francisco xavier', 'u', 'educacion'],
      ),
      LocalPlace(
        name: 'Universidad Andina Simón Bolívar',
        category: 'Universidad',
        coordinates: LatLng(-19.0528, -65.2598),
        searchTerms: ['universidad', 'andina', 'simon bolivar', 'uasb'],
      ),

      // BANCOS
      LocalPlace(
        name: 'Banco Nacional de Bolivia (Plaza)',
        category: 'Banco',
        coordinates: LatLng(-19.0492, -65.2595),
        searchTerms: ['banco', 'bnb', 'nacional', 'cajero', 'dinero'],
      ),
      LocalPlace(
        name: 'Banco Mercantil Santa Cruz',
        category: 'Banco',
        coordinates: LatLng(-19.0485, -65.2601),
        searchTerms: ['banco', 'mercantil', 'bmsc', 'cajero'],
      ),
      LocalPlace(
        name: 'Banco Unión',
        category: 'Banco',
        coordinates: LatLng(-19.0488, -65.2588),
        searchTerms: ['banco', 'union', 'cajero'],
      ),

      // CENTROS COMERCIALES Y TIENDAS
      LocalPlace(
        name: 'Ketal Supermercado',
        category: 'Supermercado',
        coordinates: LatLng(-19.0395, -65.2555),
        searchTerms: ['ketal', 'supermercado', 'super', 'compras', 'tienda'],
      ),
      LocalPlace(
        name: 'Hipermaxi',
        category: 'Supermercado',
        coordinates: LatLng(-19.0372, -65.2548),
        searchTerms: ['hipermaxi', 'hiper', 'supermercado', 'compras'],
      ),
      LocalPlace(
        name: 'IC Norte Shopping',
        category: 'Centro Comercial',
        coordinates: LatLng(-19.0385, -65.2562),
        searchTerms: ['ic norte', 'shopping', 'centro comercial', 'mall'],
      ),

      // PARQUES Y PLAZAS
      LocalPlace(
        name: 'Plaza 25 de Mayo',
        category: 'Plaza',
        coordinates: LatLng(-19.0489, -65.2593),
        searchTerms: ['plaza', '25 de mayo', 'principal', 'parque'],
      ),
      LocalPlace(
        name: 'Parque Simón Bolívar',
        category: 'Parque',
        coordinates: LatLng(-19.04268, -65.26268),
        searchTerms: ['parque', 'bolivar', 'simon bolivar', 'verde', 'km 7'],
      ),
      LocalPlace(
        name: 'Parque La Loma',
        category: 'Parque',
        coordinates: LatLng(-19.0512, -65.2642),
        searchTerms: ['parque', 'loma', 'la loma'],
      ),

      // TRANSPORTE
      LocalPlace(
        name: 'Terminal de Buses',
        category: 'Terminal',
        coordinates: LatLng(-19.03968, -65.24682),
        searchTerms: ['terminal', 'buses', 'transporte', 'viaje'],
      ),
      LocalPlace(
        name: 'Aeropuerto Juana Azurduy',
        category: 'Aeropuerto',
        coordinates: LatLng(-19.0071, -65.2887),
        searchTerms: ['aeropuerto', 'juana azurduy', 'azurduy', 'avion', 'vuelo'],
      ),

      // HOTELES
      LocalPlace(
        name: 'Hotel Parador Santa María La Real',
        category: 'Hotel',
        coordinates: LatLng(-19.0495, -65.2601),
        searchTerms: ['hotel', 'parador', 'santa maria', 'hospedaje'],
      ),
      LocalPlace(
        name: 'Hotel Gran Mariscal',
        category: 'Hotel',
        coordinates: LatLng(-19.0483, -65.2598),
        searchTerms: ['hotel', 'gran mariscal', 'mariscal', 'hospedaje'],
      ),

      // RESTAURANTES Y COMIDA
      LocalPlace(
        name: 'Mercado Campesino (Comida)',
        category: 'Restaurante',
        coordinates: LatLng(-19.0442, -65.2625),
        searchTerms: ['comida', 'almuerzo', 'restaurante', 'mercado'],
      ),
      LocalPlace(
        name: 'Salteñería El Paceño',
        category: 'Salteñería',
        coordinates: LatLng(-19.0468, -65.2592),
        searchTerms: ['salteña', 'paceño', 'desayuno', 'comida'],
      ),

      // INSTITUCIONES PÚBLICAS
      LocalPlace(
        name: 'Alcaldía de Sucre',
        category: 'Gobierno',
        coordinates: LatLng(-19.0487, -65.2594),
        searchTerms: ['alcaldia', 'municipio', 'gobierno', 'tramites'],
      ),
      LocalPlace(
        name: 'Gobernación de Chuquisaca',
        category: 'Gobierno',
        coordinates: LatLng(-19.0491, -65.2589),
        searchTerms: ['gobernacion', 'prefectura', 'gobierno'],
      ),
      LocalPlace(
        name: 'SEGIP Sucre',
        category: 'Institución',
        coordinates: LatLng(-19.0425, -65.2572),
        searchTerms: ['segip', 'carnet', 'identidad', 'cedula', 'tramite'],
      ),

      // FARMACIAS
      LocalPlace(
        name: 'Farmacia Chávez',
        category: 'Farmacia',
        coordinates: LatLng(-19.0486, -65.2597),
        searchTerms: ['farmacia', 'chavez', 'medicamentos', 'medicina'],
      ),
      LocalPlace(
        name: 'Farmacia Boliviana',
        category: 'Farmacia',
        coordinates: LatLng(-19.0479, -65.2602),
        searchTerms: ['farmacia', 'boliviana', 'medicamentos'],
      ),
    ];
  }

  /// Busca lugares en la base de datos local
  static List<LocalPlace> search(String query) {
    if (query.trim().isEmpty) {
      return [];
    }

    List<LocalPlace> results = [];
    for (var place in getAllPlaces()) {
      if (place.matches(query)) {
        results.add(place);
      }
    }

    return results;
  }
}
