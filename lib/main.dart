import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rastreador de Distancia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LocationTrackerScreen(),
    );
  }
}

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  bool isTracking = false;
  double distanceInMeters = 0.0;
  Position? lastPosition;
  List<Position> positions = [];
  String statusMessage = '';
  double speedInMetersPerSecond = 0.0;
  StreamSubscription<Position>? positionStreamSubscription;
  DateTime? lastUpdateTime;
  double tarifaTotal = 0.0;
  double ultimaDistanciaCobrada = 0.0;
  int pasajerosAdultos = 1;
  int pasajerosNinos = 0;

  double calcularTarifaInicial() {
    double tarifa = 5.0; // Tarifa base por el primer adulto

    // Sumar por adultos adicionales
    if (pasajerosAdultos > 1) {
      tarifa += (pasajerosAdultos - 1) * 3.0;
    }

    // Sumar por niños
    tarifa += pasajerosNinos * 2.0;

    return tarifa;
  }


  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          statusMessage = 'Activa el GPS';
        });
        return;
      }

      var permission = await Permission.location.request();
      if (permission.isDenied) {
        setState(() {
          statusMessage = 'Necesito permisos de ubicación';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        statusMessage = 'GPS listo (${position.accuracy.toStringAsFixed(1)} m)';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error al inicializar GPS: $e';
      });
    }
  }


  bool _isValidMovement(Position position) {
    if (lastPosition == null) {
      lastUpdateTime = DateTime.now();
      return true;
    }

    // Verificar la precisión horizontal
    if (position.accuracy > 15) {
      setState(() {
        statusMessage =
        'Esperando mejor precisión: ${position.accuracy.toStringAsFixed(1)} m';
      });
      return false;
    }

    // Obtener la velocidad actual
    speedInMetersPerSecond = position.speed;

    // Si la velocidad es muy baja, consideramos que no hay movimiento
    if (speedInMetersPerSecond < 0.5) { // menos de 0.5 m/s ≈ 1.8 km/h
      setState(() {
        statusMessage = 'Detenido';
      });
      return false;
    }

    // Calcular tiempo desde última actualización
    DateTime now = DateTime.now();
    Duration timeSinceLastUpdate = now.difference(lastUpdateTime!);

    // Solo actualizar si han pasado al menos 2 segundos
    if (timeSinceLastUpdate.inMilliseconds < 2000) {
      return false;
    }

    // Verificar si hay movimiento real
    double distance = Geolocator.distanceBetween(
      lastPosition!.latitude,
      lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    // Solo considerar movimientos mayores a 2 metros
    if (distance < 1.5) {
      setState(() {
        statusMessage = 'Movimiento muy pequeño';
      });
      return false;
    }

    // Actualizar tiempo de última actualización válida
    lastUpdateTime = now;
    return true;
  }

  double _ultimaTarifaInicial = 0.0; // Añade esta variable al inicio de la clase

  void _actualizarTarifa() {
    if (ultimaDistanciaCobrada == 0) {
      setState(() {
        // Guardamos la tarifa inicial separada
        _ultimaTarifaInicial = calcularTarifaInicial();
        tarifaTotal = _ultimaTarifaInicial;

        // Si ya superamos los 3 metros iniciales
        if (distanceInMeters > 3) {
          double metrosExtra = distanceInMeters - 3;
          int metrosExtraRedondeados = metrosExtra.floor();
          // Calculamos el extra por metros y lo sumamos a la tarifa inicial
          double tarifaExtra = metrosExtraRedondeados * 1.5;
          tarifaTotal = _ultimaTarifaInicial + tarifaExtra;
          ultimaDistanciaCobrada = 3.0 + metrosExtraRedondeados.toDouble();
        } else {
          ultimaDistanciaCobrada = distanceInMeters.floor().toDouble();
        }
      });
    } else {
      double nuevaDistancia = distanceInMeters - ultimaDistanciaCobrada;

      if (nuevaDistancia >= 1.0) {
        setState(() {
          int metrosNuevos = nuevaDistancia.floor();
          // Usamos la última tarifa inicial guardada
          tarifaTotal = _ultimaTarifaInicial +
              ((distanceInMeters - 3).floor() * 1.5);
          ultimaDistanciaCobrada += metrosNuevos.toDouble();
        });
      }
    }
  }

  void _startTracking() {
    setState(() {
      isTracking = true;
      distanceInMeters = 0.0;
      positions.clear();
      lastPosition = null;
      lastUpdateTime = null;
      statusMessage = 'Iniciando rastreo...';
      tarifaTotal = 0.0;
      ultimaDistanciaCobrada = 0.0;
    });

    try {
      positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen(
            (Position position) {
          if (!isTracking) return;

          if (_isValidMovement(position)) {
            if (lastPosition != null) {
              double newDistance = Geolocator.distanceBetween(
                lastPosition!.latitude,
                lastPosition!.longitude,
                position.latitude,
                position.longitude,
              );

              setState(() {
                distanceInMeters += newDistance;
                positions.add(position);
                statusMessage = '''
Velocidad: ${speedInMetersPerSecond.toStringAsFixed(1)} m/h
Precisión: ${position.accuracy.toStringAsFixed(1)} m
''';
              });
              _actualizarTarifa();
            } else {
              setState(() {
                positions.add(position);
                statusMessage = 'Primera posición registrada';
              });
            }
            lastPosition = position;
          }
        },
        onError: (error) {
          setState(() {
            statusMessage = 'Error de GPS: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        statusMessage = 'Error al iniciar rastreo: $e';
        isTracking = false;
      });
    }
  }

  void _stopTracking() {
    positionStreamSubscription?.cancel();
    setState(() {
      isTracking = false;
      lastPosition = null;
      lastUpdateTime = null;
      statusMessage = 'Rastreo detenido';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ChaliTaxi',
          style: TextStyle(
            color: Colors.red,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',  // Si no tienes esta fuente, puedes quitarla
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,  // Para centrarlo como en la imagen
      ),
      body: Column(
        children: [
          // Sección Pasajeros
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                const Text(
                  'Pasajeros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Adultos
                    Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Adultos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red[400],
                                    size: 20
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: !isTracking && pasajerosAdultos > 1
                                    ? () => setState(() => pasajerosAdultos--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: Text(
                                  '$pasajerosAdultos',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors.red[400],
                                    size: 20
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: !isTracking
                                    ? () => setState(() => pasajerosAdultos++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Niños
                    Container(
                      width: 168,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Niños',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red[400],
                                    size: 20
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: !isTracking && pasajerosNinos > 0
                                    ? () => setState(() => pasajerosNinos--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: Text(
                                  '$pasajerosNinos',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors.red[400],
                                    size: 20
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: !isTracking
                                    ? () => setState(() => pasajerosNinos++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sección Tarifa
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                const Text(
                  'Tarifa inicial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Bs. ${calcularTarifaInicial().toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Tarifa estimada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bs. ${tarifaTotal.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                Text(
                  '${distanceInMeters.toStringAsFixed(1)} metros recorridos',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Sección Distancia y botón
          Flexible(
            flex: 3, // Reduce el espacio que toma (menor número = menos espacio)
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, // Reduce el ancho al 90% de la pantalla
              padding: const EdgeInsets.symmetric(vertical: 20), // Reduce el padding vertical
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Cambiado a center
                mainAxisSize: MainAxisSize.min, // Hace que el Column tome el mínimo espacio necesario
                children: [
                  Column(
                    children: [
                      Text(
                        '${distanceInMeters.toStringAsFixed(1)} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Espacio específico entre elementos
                  Container(
                    width: 110,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTracking ? Colors.white : Colors.green,
                        foregroundColor: isTracking ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: isTracking ? _stopTracking : _startTracking,
                      child: Text(
                        isTracking ? 'Detener' : 'Iniciar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}