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
    double tarifa = 5.0;  // Tarifa base por el primer adulto

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
    if (position.accuracy > 20) {
      setState(() {
        statusMessage = 'Esperando mejor precisión: ${position.accuracy.toStringAsFixed(1)}m';
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
    if (distance < 2) {
      setState(() {
        statusMessage = 'Movimiento muy pequeño';
      });
      return false;
    }

    // Actualizar tiempo de última actualización válida
    lastUpdateTime = now;
    return true;
  }

  void _actualizarTarifa() {
    // Si aún no hemos cobrado nada (inicio del viaje)
    if (ultimaDistanciaCobrada == 0) {
      setState(() {
        // Aplicamos la tarifa inicial
        tarifaTotal = calcularTarifaInicial();

        // Si ya superamos los 3 metros iniciales
        if (distanceInMeters > 3) {
          // Calculamos cuántos metros extra después de los 3 metros
          double metrosExtra = distanceInMeters - 3;
          // Añadimos 1.5 Bs por cada metro extra
          tarifaTotal += metrosExtra.floor() * 1.5;
          ultimaDistanciaCobrada = 3.0 + metrosExtra.floor().toDouble();
        } else {
          ultimaDistanciaCobrada = distanceInMeters.floor().toDouble();
        }
      });
    } else if (distanceInMeters > 3) {
      // Para actualizaciones posteriores, calculamos nuevos metros extra
      double nuevosMetros = distanceInMeters - ultimaDistanciaCobrada;
      if (nuevosMetros >= 1) {
        setState(() {
          tarifaTotal += nuevosMetros.floor() * 1.5;
          ultimaDistanciaCobrada += nuevosMetros.floor().toDouble();
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
          accuracy: LocationAccuracy.best,
          distanceFilter: 2, // Mínimo 2 metros de movimiento
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
Velocidad: ${speedInMetersPerSecond.toStringAsFixed(1)} m/s
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
      appBar: AppBar(
        title: const Text('Rastreador de Distancia'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text('Adultos'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: !isTracking && pasajerosAdultos > 1
                              ? () => setState(() => pasajerosAdultos--)
                              : null,
                        ),
                        Text('$pasajerosAdultos'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: !isTracking
                              ? () => setState(() => pasajerosAdultos++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    const Text('Niños'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: !isTracking && pasajerosNinos > 0
                              ? () => setState(() => pasajerosNinos--)
                              : null,
                        ),
                        Text('$pasajerosNinos'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: !isTracking
                              ? () => setState(() => pasajerosNinos++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tarifa inicial
            Text(
              'Tarifa inicial: ${calcularTarifaInicial().toStringAsFixed(1)} Bs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),

            Text(
              'Tarifa actual:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              '${tarifaTotal.toStringAsFixed(1)} Bs',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Distancia total:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              '${distanceInMeters.toStringAsFixed(1)} metros',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Velocidad: ${speedInMetersPerSecond.toStringAsFixed(1)} m/s',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: isTracking ? _stopTracking : _startTracking,
              child: Text(
                isTracking ? 'DETENER' : 'INICIAR',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Puntos GPS: ${positions.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}