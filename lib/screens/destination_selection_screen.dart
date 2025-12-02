import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/destination.dart';
import 'route_map_screen.dart';

/// Pantalla para seleccionar un destino
class DestinationSelectionScreen extends StatefulWidget {
  const DestinationSelectionScreen({super.key});

  @override
  State<DestinationSelectionScreen> createState() =>
      _DestinationSelectionScreenState();
}

class _DestinationSelectionScreenState
    extends State<DestinationSelectionScreen> {
  List<Destination> destinations = [];
  Position? currentPosition;
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    destinations = DestinationData.getPopularDestinations();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoadingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor activa el GPS'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  void _selectDestination(Destination destination) {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación actual...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a la pantalla del mapa con la ruta
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapScreen(
          currentPosition: currentPosition!,
          destination: destination,
        ),
      ),
    );
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
          'Seleccionar Destino',
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
          // Estado de ubicación
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isLoadingLocation
                ? Colors.orange[100]
                : Colors.green[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLoadingLocation
                      ? Icons.location_searching
                      : Icons.location_on,
                  color: isLoadingLocation ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isLoadingLocation
                      ? 'Obteniendo ubicación...'
                      : 'Ubicación lista',
                  style: TextStyle(
                    color: isLoadingLocation ? Colors.orange[900] : Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Lista de destinos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_city,
                        color: Colors.red[600],
                        size: 30,
                      ),
                    ),
                    title: Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      destination.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    onTap: () => _selectDestination(destination),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
