import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:pompa_benzina/services/ad_service.dart';
import 'dart:async';
import '../models/gas_station.dart';
import '../models/vehicle.dart';
import '../services/gas_station_service.dart';
import 'nearest_stations_page.dart';
import 'cheapest_stations_page.dart';
import 'average_price_page.dart';
import 'car_stats_page.dart' as car_stats;
import '../services/preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/maps_service.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_page.dart';
// ignore: unused_import
import 'splash_screen.dart';
import '../widgets/responsive_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Funzione helper per log colorati
// void logInfo(String message) {
//   developer.log('\x1B[33m$message\x1B[0m', name: 'HOME_PAGE');
// }

// void logError(String message) {
//   developer.log('\x1B[31m$message\x1B[0m', name: 'HOME_PAGE_ERROR');
// }

class _HomePageState extends State<HomePage> {
  final GasStationService _service = GasStationService();
  final PreferencesService _prefsService = PreferencesService();
  List<GasStation> _stations = [];
  // ignore: unused_field
  List<Vehicle> _vehicles = [];
  // ignore: unused_field
  Vehicle? _selectedVehicle;
  // ignore: unused_field
  bool _isLoading = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  LatLng _currentPosition = const LatLng(0, 0); // Default position

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _getCurrentLocation(); // Nuovo metodo per ottenere la posizione
    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Richiedi il permesso di geolocalizzazione
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permesso di geolocalizzazione negato');
        }
      }

      // Ottieni la posizione corrente
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Aggiorna la posizione corrente
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Carica le stazioni vicine
      await _loadNearbyStations();
    } catch (e) {
      //  logError('Errore nella geolocalizzazione: $e');
      // Fallback su una posizione di default o mostra un errore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile ottenere la posizione corrente'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyStations() async {
    try {
      int distance = await _prefsService.getSearchRadius();
      final stations = await _service.getGasStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        distance, // raggio in km
      );

      if (mounted && stations.isNotEmpty) {
        setState(() {
          _stations = stations;
          _markers = _createMarkersFromStations(stations);
        });

        // Centra la mappa sulla posizione corrente
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
        );
      }
    } catch (e) {
      //logError('Errore nel caricamento stazioni: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await _prefsService.getVehicles();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        if (vehicles.isNotEmpty) {
          _selectedVehicle = vehicles.first;
        }
      });
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd()
      ..load().then((value) {
        if (mounted) {
          // Verifica che il widget sia ancora montato
          setState(() {
            _isBannerAdReady = true;
          });
        }
      }).catchError((error) {
        print('Errore nel caricamento del banner: $error');
        _isBannerAdReady = false;
        _bannerAd = null;
      });
  }

  // Metodo per creare markers dalle stazioni
  Set<Marker> _createMarkersFromStations(List<GasStation> stations) {
    final Set<Marker> markers = stations.map((station) {
      // Calcoliamo il colore del marker in base al prezzo
      BitmapDescriptor markerIcon;

      // Verifica se ha un prezzo per la benzina self service
      final benzinaPrice =
          station.getLowestPrice('Benzina', selfServiceOnly: true);
      if (benzinaPrice != null) {
        // Determina il colore in base al prezzo
        if (benzinaPrice < 1.8) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else if (benzinaPrice < 2.0) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
        } else {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        }
      } else {
        markerIcon = BitmapDescriptor.defaultMarker;
      }

      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: station.name,
          snippet: 'Benzina: €${benzinaPrice?.toStringAsFixed(3) ?? "N/D"}',
        ),
        onTap: () => _showStationDetails(station),
      );
    }).toSet();

    // Aggiungi marker per posizione corrente
    markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: _currentPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'La tua posizione'),
    ));

    return markers;
  }

  // Mostra i dettagli della stazione in un bottom sheet migliorato
  void _showStationDetails(GasStation station) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle per trascinare
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Intestazione con nome e logo
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(station.address),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_gas_station, size: 32),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Prezzi carburante
                Text(
                  'Prezzi carburante',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                // Card per i prezzi dei carburanti
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildFuelPriceRow('Benzina', station.fuelPrices),
                        const Divider(),
                        _buildFuelPriceRow('Gasolio', station.fuelPrices),
                        const Divider(),
                        _buildFuelPriceRow('GPL', station.fuelPrices),
                        if (station.fuelPrices.containsKey('Metano')) ...[
                          const Divider(),
                          _buildFuelPriceRow('Metano', station.fuelPrices),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Mappa statica
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    MapsService.getStaticMapUrl(
                      station.latitude,
                      station.longitude,
                      zoom: 15,
                      width: 400,
                      height: 200,
                    ),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline, size: 48),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Pulsanti azioni
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.directions,
                      label: 'Indicazioni',
                      onTap: () => _openMaps(station),
                    ),
                    _buildActionButton(
                      icon: Icons.star_outline,
                      label: 'Preferiti',
                      onTap: () {
                        // Aggiungi ai preferiti
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Costruisce una riga per il prezzo del carburante
  Widget _buildFuelPriceRow(String fuelType, Map<String, PriceInfo> prices) {
    final price = prices[fuelType];
    if (price == null) {
      return _buildPriceRow(fuelType, null, null);
    }
    return Column(
      children: [
        _buildPriceRow('$fuelType (Self)', price.self, price.lastUpdate),
        if (price.servito > 0)
          _buildPriceRow(
              '$fuelType (Servito)', price.servito, price.lastUpdate),
      ],
    );
  }

  Widget _buildPriceRow(String label, double? price, DateTime? lastUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price != null ? '€${price.toStringAsFixed(3)}' : 'N/D',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (lastUpdate != null)
              Text(
                'Agg. ${DateFormat('dd/MM HH:mm').format(lastUpdate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  // Costruisce un pulsante di azione
  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ],
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
      appBar: ResponsiveAppBar(
        onRefresh: _getCurrentLocation,
        onSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsPage(
                onSettingsChanged: () async {
                  if (mounted) {
                    setState(() => _isLoading = true);
                    await _loadNearbyStations();
                    setState(() => _isLoading = false);
                  }
                },
              ),
            ),
          );
        },
      ),
      body: _isLoading
          ? const SplashScreen(isLoading: true) // Modifica qui
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                (!kIsWeb ||
                        MediaQueryData.fromView(View.of(context)).size.width <
                            600)
                    ? NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          // Debug print per verificare se le gesture vengono rilevate
                          print('Scroll fraction: ${notification.extent}');
                          return true;
                        },
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.4,
                          minChildSize: 0.1,
                          maxChildSize: 0.9,
                          snap: true, // Aggiunto snap per migliore feedback
                          snapSizes: const [
                            0.1,
                            0.4,
                            0.9
                          ], // Punti di snap definiti
                          builder: (context, scrollController) {
                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: CustomScrollView(
                                controller: scrollController,
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        // Handle bar migliorato
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Container(
                                            height: 5,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
                                            ),
                                          ),
                                        ),
                                        // Content
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.8,
                                          child: IndexedStack(
                                            index: _selectedIndex,
                                            children: [
                                              NearestStationsPage(
                                                stations: _stations,
                                                onStationSelected:
                                                    _selectStation,
                                              ),
                                              CheapestStationsPage(
                                                stations: _stations,
                                                onStationSelected:
                                                    _selectStation,
                                              ),
                                              AveragePricePage(
                                                  stations: _stations),
                                              const car_stats.CarStatsPage(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: _selectedIndex != -1,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition,
                                  zoom: 14,
                                ),
                                markers: _markers,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                onMapCreated: (controller) =>
                                    _mapController = controller,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onVerticalDragUpdate: (_) {},
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
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
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_bannerAd != null &&
              _isBannerAdReady) // Verifica entrambe le condizioni
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          BottomNavigationBar(
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
                label: '+ ECONOMICI',
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
        ],
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
