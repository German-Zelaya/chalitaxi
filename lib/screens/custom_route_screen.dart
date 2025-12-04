import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../services/geocoding_service.dart';
import 'map_picker_screen.dart';
import 'route_map_screen.dart';

/// Pantalla para crear una ruta personalizada
class CustomRouteScreen extends StatefulWidget {
  final int adultos;
  final int ninos;

  const CustomRouteScreen({
    super.key,
    required this.adultos,
    required this.ninos,
  });

  @override
  State<CustomRouteScreen> createState() => _CustomRouteScreenState();
}

class _CustomRouteScreenState extends State<CustomRouteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GeocodingService _geocodingService = GeocodingService();

  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
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
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _geocodingService.searchPlace(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación actual...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Crear un destino temporal con el resultado de búsqueda
    final destination = Destination(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: result.displayName.split(',').first, // Tomar solo la primera parte
      description: result.displayName,
      coordinates: result.coordinates,
      icon: Icons.place, // Ícono genérico para lugares personalizados
    );

    // Navegar a la pantalla del mapa con la ruta
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapScreen(
          currentPosition: _currentPosition!,
          destination: destination,
          adultos: widget.adultos,
          ninos: widget.ninos,
        ),
      ),
    );
  }

  void _openMapPicker() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación actual...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a la pantalla de selección en mapa
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          currentPosition: _currentPosition!,
        ),
      ),
    );

    if (selectedLocation != null && mounted) {
      // Obtener el nombre del lugar seleccionado
      setState(() {
        _isSearching = true;
      });

      String placeName = 'Destino personalizado';
      final name = await _geocodingService.getPlaceName(selectedLocation);
      if (name != null) {
        placeName = name;
      }

      setState(() {
        _isSearching = false;
      });

      // Crear destino y navegar
      final destination = Destination(
        id: 'custom_map_${DateTime.now().millisecondsSinceEpoch}',
        name: placeName.split(',').first,
        description: placeName,
        coordinates: selectedLocation,
        icon: Icons.my_location,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteMapScreen(
              currentPosition: _currentPosition!,
              destination: destination,
              adultos: widget.adultos,
              ninos: widget.ninos,
            ),
          ),
        );
      }
    }
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
          'Ruta Personalizada',
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
            color: _isLoadingLocation
                ? Colors.orange[100]
                : Colors.green[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isLoadingLocation
                      ? Icons.location_searching
                      : Icons.location_on,
                  color: _isLoadingLocation ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoadingLocation
                      ? 'Obteniendo ubicación...'
                      : 'Ubicación lista',
                  style: TextStyle(
                    color: _isLoadingLocation ? Colors.orange[900] : Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Información de pasajeros
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border(
                bottom: BorderSide(color: Colors.red[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pasajeros: ${widget.adultos} adulto${widget.adultos > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (widget.ninos > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+ ${widget.ninos} niño${widget.ninos > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buscar destino',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Hospital Santa Bárbara, Calle Arenales...',
                    prefixIcon: Icon(Icons.search, color: Colors.red[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    // Buscar después de 500ms de inactividad
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _searchPlaces(value);
                      }
                    });
                  },
                  onSubmitted: _searchPlaces,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón para seleccionar en mapa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: Icon(Icons.map, color: Colors.blue[700]),
                label: Text(
                  'O selecciona el destino en el mapa',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue[700]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Resultados de búsqueda
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.place,
                          color: Colors.red[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        result.displayName.split(',').first,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        result.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.red[400],
                        size: 16,
                      ),
                      onTap: () => _selectSearchResult(result),
                    ),
                  );
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron resultados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Busca un lugar o selecciona en el mapa',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
