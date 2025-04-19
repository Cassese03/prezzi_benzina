// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:io' show Platform;

import 'package:carmate/services/car_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:carmate/services/ad_service.dart';
import 'dart:async';
import '../models/gas_station.dart';
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
import 'package:seo/seo.dart';
import 'splash_screen.dart';
import '../widgets/responsive_app_bar.dart';
import '../widgets/multi_step_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GasStationService _service = GasStationService();
  final PreferencesService _prefsService = PreferencesService();
  List<GasStation> _stations = [];
  late BitmapDescriptor markerBlue;
  late BitmapDescriptor markerGreen;
  late BitmapDescriptor markerOrange;
  late BitmapDescriptor markerRed;
  late BitmapDescriptor markerDefault;
  bool _isLoading = false;
  bool _isLoadingWithSteps = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  LatLng _currentPosition = const LatLng(0, 0); // Default position

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _isLoadingWithSteps = true;
    _loadCustomMarkers();
    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  Future<void> _loadCustomMarkers() async {
    markerBlue = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 38)),
      'assets/markers/MarkerBlu.png',
    );
    markerGreen = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 38)),
      'assets/markers/MarkerVerde.png',
    );
    markerOrange = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 38)),
      'assets/markers/MarkerArancione.png',
    );
    markerRed = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 38)),
      'assets/markers/MarkerRosso.png',
    );
    markerDefault = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 38)),
      'assets/markers/MarkerRosso.png',
    );
  }

  Future<void> _loadNearbyStations() async {
    try {
      int distance = await _prefsService.getSearchRadius();
      final stations = await _service.getGasStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        distance,
      );

      if (mounted && stations.isNotEmpty) {
        setState(() {
          _stations = stations;
          _markers = _createMarkersFromStations(stations);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
        );
      }
      // ignore: empty_catches
    } catch (e) {}
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
        if (vehicles.isNotEmpty) {}
      });
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd()
      ..load().then((value) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      }).catchError((error) {
        _isBannerAdReady = false;
        _bannerAd = null;
      });
  }

  Set<Marker> _createMarkersFromStations(List<GasStation> stations) {
    final Set<Marker> markers = stations.map((station) {
      BitmapDescriptor markerIcon;
      final benzinaPrice =
          station.getLowestPrice('Benzina', selfServiceOnly: true);

      if (station.tipo == 'Elettrica') {
        markerIcon = kIsWeb
            ? markerBlue
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      } else {
        if (benzinaPrice != null) {
          if (benzinaPrice < 1.8) {
            markerIcon = (kIsWeb)
                ? markerGreen
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen);
          } else if (benzinaPrice < 2.0) {
            markerIcon = (kIsWeb)
                ? markerOrange
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange);
          } else {
            markerIcon = (kIsWeb)
                ? markerRed
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed);
          }
        } else {
          markerIcon = (kIsWeb)
              ? markerDefault
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        }
      }

      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: station.name,
          snippet: (station.tipo != 'Elettrica')
              ? 'Benzina: €${benzinaPrice?.toStringAsFixed(3) ?? "N/D"}'
              : '${station.fuelPrices['Elettrica']!.potenzaKw} kW',
        ),
        onTap: () => _showStationDetails(station),
      );
    }).toSet();

    return markers;
  }

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
                      child: Icon(
                        (station.tipo == 'Elettrica')
                            ? Icons.ev_station
                            : Icons.local_gas_station,
                        color: (station.tipo == 'Elettrica')
                            ? Colors.lightBlue
                            : const Color(0xFF2C3E50),
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Prezzi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        (station.tipo == 'Elettrica')
                            ? _buildPriceRowEle(
                                'Elettrica',
                                '${station.fuelPrices['Elettrica']!.potenzaKw} kW',
                                station.fuelPrices['Elettrica']?.lastUpdate,
                              )
                            : _buildFuelPriceRow('Benzina', station.fuelPrices),
                        const Divider(),
                        (station.tipo == 'Elettrica')
                            ? const Text('')
                            : _buildFuelPriceRow('Gasolio', station.fuelPrices),
                        (station.tipo == 'Elettrica')
                            ? const Text('')
                            : const Divider(),
                        (station.tipo == 'Elettrica')
                            ? const Text('')
                            : _buildFuelPriceRow('GPL', station.fuelPrices),
                        if (station.fuelPrices.containsKey('Metano')) ...[
                          const Divider(),
                          _buildFuelPriceRow('Metano', station.fuelPrices),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.directions,
                      label: 'Indicazioni',
                      onTap: () => _openMaps(station),
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

  Widget _buildPriceRowEle(String label, String? price, DateTime? lastUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price ?? 'N/D',
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

  void _handleLoadingComplete() {
    setState(() {
      _isLoadingWithSteps = false;
      _isLoading = false;
    });
  }

  Future<void> _handleLocationPermissionGranted() async {
    await _loadVehicles();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _fetchData(Position position) async {
    try {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      await _loadNearbyStations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile ottenere i dati'),
          ),
        );
      }
    }
  }

  void _startLoading() {
    setState(() {
      _isLoadingWithSteps = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SeoController(
      enabled: true,
      tree: WidgetTree(context: context),
      child: Scaffold(
        appBar: ResponsiveAppBar(
          onRefresh: () {
            _startLoading();
          },
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
        body: _isLoadingWithSteps
            ? MultiStepLoading(
                onLocationPermissionGranted: _handleLocationPermissionGranted,
                onFetchData: _fetchData,
                onCompleted: _handleLoadingComplete,
              )
            : _isLoading
                ? const SplashScreen(isLoading: true)
                : MediaQuery.of(context).size.width >
                        MediaQuery.of(context).size.height
                    ? Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition,
                                zoom: 14,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapType: MapType.normal,
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                            ),
                          ),
                          Expanded(
                            child: NotificationListener<
                                DraggableScrollableNotification>(
                              onNotification: (notification) {
                                setState(() {});
                                return true;
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
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
                        ],
                      )
                    : Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: Seo.image(
                                src:
                                    "https://carmate-website.vercel.app/assets/assets/images/logo.png",
                                alt: 'CarMate App Logo',
                                child: Image.asset(
                                  "assets/images/logo.png",
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0,
                            child: Column(
                              children: [
                                Seo.text(
                                  text:
                                      'TankMap - Trova i Migliori Prezzi del Carburante',
                                  style: TextTagStyle.h1,
                                  child: const Text(''),
                                ),
                                Seo.text(
                                  text:
                                      'TankMap è l\'app definitiva per trovare i prezzi più convenienti del carburante. Confronta benzina, diesel, GPL e metano nelle stazioni di servizio vicino a te. Risparmia sui rifornimenti e gestisci i consumi dei tuoi veicoli con statistiche dettagliate.',
                                  style: TextTagStyle.h2,
                                  child: const Text(''),
                                ),
                                Seo.image(
                                  src:
                                      "https://carmate-website.vercel.app/assets/assets/images/logo.png",
                                  alt:
                                      'TankMap - App per il risparmio sul carburante',
                                  child: const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentPosition,
                              zoom: 14,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapType: MapType.normal,
                            onMapCreated: (controller) =>
                                _mapController = controller,
                          ),
                          NotificationListener<DraggableScrollableNotification>(
                            onNotification: (notification) {
                              setState(() {});
                              return true;
                            },
                            child: DraggableScrollableSheet(
                              initialChildSize: 0.4,
                              minChildSize: 0.1,
                              maxChildSize: 0.8,
                              builder: (context, scrollController) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      IgnorePointer(
                                        ignoring: false,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      Expanded(
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
                                            AveragePricePage(
                                                stations: _stations),
                                            const car_stats.CarStatsPage(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb && _bannerAd != null && _isBannerAdReady)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFE67E22),
              selectedIconTheme: const IconThemeData(
                color: Color(0xFFE67E22),
                size: 28,
              ),
              unselectedItemColor: const Color(0xFF2C3E50),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFF2C3E50),
                size: 24,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.near_me_outlined),
                  activeIcon: Icon(Icons.near_me),
                  label: 'KM VICINI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_gas_station_outlined),
                  activeIcon: Icon(Icons.local_gas_station),
                  label: 'ECONOMICI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart_outlined),
                  activeIcon: Icon(Icons.show_chart),
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
      ),
    );
  }

  void _selectStation(GasStation station) async {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        15,
      ),
    );
    if (Platform.isAndroid || Platform.isIOS) {
      final isCarMode = await CarService.isRunningInCar();
      if (isCarMode) {
        await CarService.showStationInCar(station);
      } else {
        _showStationDetails(station);
      }
    }
  }
}

class LocationPermissionDialog {
  static Future<void> showLocationPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accesso alla posizione'),
          content: const Text(
            'Per mostrarti le stazioni di servizio più vicine, abbiamo bisogno di accedere alla tua posizione. '
            'Vuoi consentire l\'accesso alla posizione?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('NON ORA'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('IMPOSTAZIONI'),
              onPressed: () async {
                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'È necessario abilitare la localizzazione per utilizzare tutte le funzionalità'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showLocationPermissionDialog(context);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await showLocationPermissionDialog(context);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await showLocationPermissionDialog(context);
      return false;
    }

    return true;
  }
}
