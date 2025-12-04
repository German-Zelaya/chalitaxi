# Sistema de Rutas Recomendadas - ChaliTaxi

## Descripción

Se ha agregado un sistema de rutas recomendadas al taxímetro ChaliTaxi. Esta funcionalidad permite al conductor ver la ruta óptima hacia destinos populares en Sucre, Chuquisaca.

## Características Implementadas

### ✅ Funcionalidad NO modificada del taxímetro
- El sistema de cálculo de tarifas sigue funcionando exactamente igual
- El rastreo GPS del recorrido no ha sido modificado
- Los contadores de pasajeros (adultos/niños) funcionan igual
- Todo el código original del taxímetro permanece intacto

### ✨ Nuevas Funcionalidades Agregadas

1. **Selección de Destinos**
   - 6 destinos populares predefinidos en Sucre:
     - Plaza 25 de Mayo
     - Terminal de Buses
     - Mercado Central
     - Parque Simón Bolívar
     - Aeropuerto Alcantarí
     - Universidad San Francisco Xavier

2. **Visualización de Rutas**
   - Mapa interactivo con OpenStreetMap (100% gratuito)
   - Ruta óptima calculada con OSRM (API gratuita)
   - Muestra distancia estimada
   - Muestra tiempo estimado de viaje
   - Calcula tarifa estimada usando las mismas tarifas del taxímetro

3. **Integración**
   - Botón flotante "Ver Rutas" en la pantalla principal
   - No interfiere con el funcionamiento del taxímetro

## Estructura de Archivos Nuevos

```
lib/
├── models/
│   ├── destination.dart      # Modelo de destinos con lugares de Sucre
│   └── route.dart            # Modelo de ruta con cálculo de tarifas
├── services/
│   └── route_service.dart    # Servicio de API OSRM
└── screens/
    ├── destination_selection_screen.dart  # Pantalla de selección
    └── route_map_screen.dart             # Pantalla del mapa
```

## APIs Utilizadas (100% Gratuitas)

1. **OSRM (Open Source Routing Machine)**
   - URL: https://router.project-osrm.org
   - Función: Calcular rutas óptimas
   - Costo: GRATIS (código abierto)

2. **OpenStreetMap**
   - URL: https://tile.openstreetmap.org
   - Función: Tiles del mapa
   - Costo: GRATIS (con límite razonable de uso)

## Dependencias Agregadas

```yaml
flutter_map: ^7.0.2    # Para mostrar mapas
latlong2: ^0.9.1       # Para coordenadas GPS
http: ^1.2.0          # Para llamadas HTTP a OSRM
```

## Cómo Usar

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar la app**:
   ```bash
   flutter run
   ```

3. **Usar la funcionalidad de rutas**:
   - En la pantalla principal, presionar el botón "Ver Rutas"
   - Seleccionar un destino de la lista
   - Ver la ruta recomendada en el mapa
   - Revisar distancia, tiempo y tarifa estimada
   - Presionar "Iniciar Viaje" para volver al taxímetro

## Cálculo de Tarifas Estimadas

La tarifa estimada se calcula usando las mismas reglas del taxímetro pero **aplicadas a KILÓMETROS** (no metros):

- **Tarifa base**: 5 Bs (primer adulto, incluye los primeros 3 km)
- **Adultos adicionales**: 3 Bs cada uno
- **Niños**: 2 Bs cada uno
- **Por distancia**: 1.5 Bs por **kilómetro** adicional después de los primeros 3 km

**NOTA IMPORTANTE**: El taxímetro original trabaja en metros, pero las rutas recomendadas trabajan en kilómetros para dar precios más realistas.

Ejemplo:
- Distancia: 5 km (5000 metros)
- Pasajeros: 2 adultos, 1 niño
- Cálculo:
  - Base: 5 Bs
  - Adulto adicional: 3 Bs
  - Niño: 2 Bs
  - Distancia extra (5 - 3 = 2 km): 2 × 1.5 = 3 Bs
  - **Total: 13 Bs**

## Agregar Más Destinos

Para agregar más destinos, editar el archivo `lib/models/destination.dart`:

```dart
Destination(
  id: 'nuevo_lugar',
  name: 'Nombre del Lugar',
  description: 'Descripción',
  coordinates: LatLng(latitud, longitud),
),
```

## Notas Importantes

- La app requiere permisos de GPS
- Se recomienda tener conexión a Internet para cargar el mapa
- Las rutas se calculan en tiempo real
- El cálculo de tarifas es estimado, el taxímetro real prevalece durante el viaje

## Próximas Mejoras Sugeridas

- [ ] Agregar más destinos populares
- [ ] Guardar destinos frecuentes
- [ ] Rutas alternativas
- [ ] Navegación paso a paso
- [ ] Modo offline con mapas descargados
- [ ] Historial de rutas

## Soporte

Si tienes problemas:
1. Verificar que tengas conexión a Internet
2. Verificar que los permisos de GPS estén habilitados
3. Ejecutar `flutter clean && flutter pub get`
