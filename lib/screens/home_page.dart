import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gas_station.dart';
import '../services/gas_station_service.dart';
// Aggiungiamo gli import per le pagine
import 'nearest_stations_page.dart';
import 'cheapest_stations_page.dart';
import 'average_price_page.dart';
import 'car_stats_page.dart' as car_stats;
import '../widgets/settings_drawer.dart';
import '../services/preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/maps_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GasStationService _service = GasStationService();
  final PreferencesService _prefsService = PreferencesService();
  List<GasStation> _stations = [];
  bool _isLoading = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(40.8518, 14.2681); // Default: Napoli
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14),
        ),
      );

      await _loadGasStations(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadGasStations(double lat, double lng) async {
    try {
      final stations = await _service.getGasStations(lat, lng, 5);

      setState(() {
        _stations = stations;
        _markers = stations.map((station) {
          return Marker(
            markerId: MarkerId(station.id),
            position: LatLng(station.latitude, station.longitude),
            infoWindow: InfoWindow(
              title: station.name,
              snippet:
                  'Benzina: €${station.fuelPrices["Benzina"]?.toStringAsFixed(3)}',
            ),
            onTap: () => _showStationDetails(station),
          );
        }).toSet();

        // Aggiungi marker per posizione corrente
        _markers.add(Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'La tua posizione'),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Riprova',
            onPressed: () => _getCurrentLocation(),
          ),
        ),
      );
    }
  }

  void _showStationDetails(GasStation station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(station.address),
                      const SizedBox(height: 8),
                      ...station.fuelPrices.entries.map(
                        (e) => Text('${e.key}: €${e.value.toStringAsFixed(3)}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Immagine della stazione
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    MapsService.getPlacePhotoUrl(
                      station.latitude,
                      station.longitude,
                    ),
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 150,
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.local_gas_station, size: 50),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mappa statica
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                MapsService.getStaticMapUrl(
                  station.latitude,
                  station.longitude,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Pulsante Google Maps
            InkWell(
              onTap: () => _openMaps(station),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Apri in Google Maps',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(GasStation station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${station.latitude},${station.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire le mappe'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trova Benzina Economica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      drawer: SettingsDrawer(
        onSettingsChanged: () async {
          // Ricarica i dati quando cambiano le impostazioni
          if (mounted) {
            final position = await Geolocator.getCurrentPosition();
            _loadGasStations(position.latitude, position.longitude);
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mappa
                Expanded(
                  flex: 1,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) => _mapController = controller,
                  ),
                ),
                // Contenuto tab
                Expanded(
                  flex: 1,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      NearestStationsPage(
                        stations: _stations,
                        onStationSelected: _selectStation,
                      ),
                      CheapestStationsPage(
                        stations: _stations,
                        onStationSelected: _selectStation,
                      ),
                      AveragePricePage(stations: _stations),
                      const car_stats.CarStatsPage(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'KM VICINI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.euro),
            label: 'PIÙ ECONOMICI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'PREZZO MEDIO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'STATISTICHE',
          ),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _selectStation(GasStation station) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        15,
      ),
    );
    // Opzionalmente mostra i dettagli della stazione
    _showStationDetails(station);
  }
}
