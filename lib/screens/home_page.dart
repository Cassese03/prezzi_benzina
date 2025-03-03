import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pompa_benzina/screens/csv_viewer_page.dart';
import 'package:pompa_benzina/screens/custom_csv_page.dart';
import 'dart:async';
import '../models/gas_station.dart';
import '../models/vehicle.dart';
import '../services/gas_station_service.dart';
import 'nearest_stations_page.dart';
import 'cheapest_stations_page.dart';
import 'average_price_page.dart';
import 'car_stats_page.dart' as car_stats;
import '../widgets/settings_drawer.dart';
import '../services/preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/maps_service.dart';
import 'dart:developer' as developer;
import '../utils/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Funzione helper per log colorati
void logInfo(String message) {
  developer.log('\x1B[33m$message\x1B[0m', name: 'HOME_PAGE');
}

void logError(String message) {
  developer.log('\x1B[31m$message\x1B[0m', name: 'HOME_PAGE_ERROR');
}

class _HomePageState extends State<HomePage> {
  final GasStationService _service = GasStationService();
  final PreferencesService _prefsService = PreferencesService();
  List<GasStation> _stations = [];
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Aggiornate le coordinate iniziali con quelle specificate
  LatLng _currentPosition = const LatLng(40.9322765492642, 14.528412503688312);

  int _selectedIndex = 0;
  bool _permissionsChecked = false;
  bool _locationPermissionChecked = false;

  // Stato del caricamento dati
  String _statusMessage = '';

  // Timer per ritardare operazioni pesanti
  Timer? _debounceTimer;

  // Controller per animazioni fluide
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _checkPermissionsAndInitialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    if (_permissionsChecked) return;

    // Usa sempre lo storage alternativo per default
    _permissionsChecked = true;

    // Inizializza direttamente lo storage alternativo
    await _setupAlternativeStorage();

    // Poi verifichiamo i permessi di posizione
    await _checkLocationPermission();

    // Inizializza l'app con la posizione o coordinate predefinite
    _initializeWithPosition();
  }

  // Nuovo metodo per configurare lo storage alternativo come opzione predefinita
  Future<void> _setupAlternativeStorage() async {
    if (!mounted) return;

    logInfo('Configurazione storage alternativo come predefinito...');

    try {
      // Crea una directory temporanea
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/csv_temp';
      final tempDirObj = Directory(tempPath);

      if (!tempDirObj.existsSync()) {
        tempDirObj.createSync(recursive: true);
      }

      // Configura i percorsi dei file
      final stationsPath = '$tempPath/gas_stations.csv';
      final pricesPath = '$tempPath/gas_prices.csv';

      // Configura il servizio per usare i percorsi alternativi
      await _service.setupAlternativeStorage(
          tempPath, stationsPath, pricesPath);

      logInfo('Storage alternativo configurato con successo: $tempPath');
    } catch (e) {
      logError('Errore nella configurazione dello storage alternativo: $e');
    }
  }

  // Non mostrare più il dialogo dei permessi poiché usiamo sempre lo storage alternativo
  void _showPermissionErrorDialog() {
    // Usa direttamente lo storage alternativo
    _setupAlternativeStorage().then((_) => _initializeWithPosition());
  }

  // Nuovo metodo per verificare i permessi di posizione
  Future<void> _checkLocationPermission() async {
    if (_locationPermissionChecked) return;

    try {
      // Verifica lo stato attuale del permesso
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Se negato, richiedi il permesso
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Se ancora negato, mostra un messaggio
        if (mounted) {
          _showLocationPermissionDialog();
        }
        return;
      }

      _locationPermissionChecked = true;
    } catch (e) {
      logError('Errore nella verifica permessi di posizione: $e');
    }
  }

  // Dialogo per i permessi di posizione
  void _showLocationPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permesso posizione'),
        content: const Text(
            'Per utilizzare tutte le funzioni dell\'app, è necessario concedere i permessi di posizione. Vuoi abilitarli nelle impostazioni?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeWithPosition(useDefaultLocation: true);
            },
            child: const Text('Usa posizione predefinita'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Apri impostazioni'),
          ),
        ],
      ),
    );
  }

  // Inizializzazione con posizione o coordinate predefinite
  Future<void> _initializeWithPosition(
      {bool useDefaultLocation = false}) async {
    setState(() => _isLoading = true);

    try {
      // Coordinate da utilizzare per la ricerca
      double latitude;
      double longitude;

      if (useDefaultLocation) {
        // Usa coordinate predefinite aggiornate
        latitude = 40.9322765492642;
        longitude = 14.528412503688312;
        logInfo('Utilizzo coordinate di default');
      } else {
        // Cerca di ottenere la posizione attuale
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );

          latitude = position.latitude;
          longitude = position.longitude;
          logInfo('Posizione corrente: $latitude, $longitude');
        } catch (e) {
          // In caso di errore, usa le coordinate fisse aggiornate
          latitude = 40.9322765492642;
          longitude = 14.528412503688312;
          logInfo(
              'Errore posizione, usando coordinate fisse: $latitude, $longitude');
        }
      }

      // Aggiorna la posizione sulla mappa
      setState(() {
        _currentPosition = LatLng(latitude, longitude);
      });

      // Avvia il download e caricamento dei dati
      await _loadData(latitude, longitude);
    } catch (e) {
      logError('Errore nell\'inizializzazione: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialogo migliorato per errori di permessi

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

  // Metodo principale per il caricamento dei dati
  Future<void> _loadData(double latitude, double longitude) async {
    if (!mounted) return;

    // Assicurati che lo storage alternativo sia configurato
    await _setupAlternativeStorage();

    // Mostra il dialogo di progresso
    _showProgressDialog('Caricamento dati', 'Preparazione...', 0.0);

    // Aggiorna status
    _updateStatus('Controllo dati CSV...');

    try {
      // Forza sempre l'aggiornamento invece di verificare se è necessario
      _updateStatus('Scaricamento file CSV...');

      // Configura il callback per monitorare il progresso (correzione dell'errore di tipo)
      _service.setDownloadProgressCallback((progress) {
        _updateProgressDialog(progress); // Non serve il cast
      });

      try {
        // Scarica i file CSV
        await _service.forceUpdate();
        _updateStatus('Download completato');
      } catch (e) {
        logError('Errore durante il download: $e');
        _updateStatus('Errore download, utilizzo file esistenti');
      } finally {
        _service.clearDownloadProgressCallback();
      }

      // Ora carica le stazioni
      _updateStatus('Caricamento stazioni...');
      await _loadGasStations(latitude, longitude, 50);

      // Chiudi il dialogo di progresso
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      logError('Errore durante il caricamento dei dati: $e');

      // Chiudi dialoghi aperti
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );

        // In caso di errore, tenta di caricare le prime 10 stazioni
        _showFirst10Stations();
      }
    }
  }

  // Aggiorna lo stato del caricamento
  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
    logInfo(message);
  }

  // Metodo per tentare di usare uno storage alternativo
  void _tryAlternativeStorage() async {
    if (!mounted) return;

    _showProgressDialog('Storage alternativo',
        'Tentativo di utilizzo storage alternativo...', 0.0);

    try {
      // Crea una directory temporanea
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/csv_temp';
      final tempDirObj = Directory(tempPath);

      if (!tempDirObj.existsSync()) {
        tempDirObj.createSync(recursive: true);
      }

      // Scarica i file CSV nella directory temporanea
      final stationsPath = '$tempPath/gas_stations.csv';
      final pricesPath = '$tempPath/gas_prices.csv';

      // Imposta il servizio per ottenere il servizio CSV di base
      final csvService = _service.getCsvService();

      // Scarica i file usando URL diretti
      await csvService.downloadToCustomLocation(
          'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv',
          stationsPath);

      await csvService.downloadToCustomLocation(
          'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv',
          pricesPath);

      // Utilizza i file personalizzati
      final success =
          await _service.useCustomCsvFiles(stationsPath, pricesPath);

      if (mounted) {
        Navigator.pop(context); // Chiude dialog di progresso

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'File CSV scaricati con successo in una posizione alternativa'),
              duration: Duration(seconds: 5),
            ),
          );

          // Riprova a caricare i dati
          _initializeWithPosition();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Non è stato possibile utilizzare lo storage alternativo'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      logError('Errore nel tentativo di storage alternativo: $e');

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Variabile per tenere traccia del dialog di progresso corrente
  BuildContext? _progressDialogContext;
  double _currentProgress = 0.0;

  // Metodo per mostrare un dialogo con barra di progresso
  void _showProgressDialog(
      String title, String message, double initialProgress) {
    if (!mounted) return;

    _currentProgress = initialProgress;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _progressDialogContext = context;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _currentProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                Text('${(_currentProgress * 100).toInt()}%'),
                const SizedBox(height: 8),
                Text(_statusMessage.isNotEmpty ? _statusMessage : message),
              ],
            ),
          );
        });
      },
    );
  }

  // Aggiorna il dialogo di progresso
  void _updateProgressDialog(double progress) {
    if (!mounted) return;

    setState(() {
      _currentProgress = progress;
    });

    // Se il dialogo è aperto, aggiorna il valore
    if (_progressDialogContext != null && mounted) {
      // Usa StatefulBuilder per aggiornare il valore senza ricreare il dialogo
      if (Navigator.canPop(_progressDialogContext!)) {
        try {
          (Navigator.of(_progressDialogContext!).overlay?.context as Element)
              .markNeedsBuild();
        } catch (e) {
          // Se non riesce ad aggiornare, ricrea il dialogo
          Navigator.of(_progressDialogContext!).pop();
          _showProgressDialog('Scaricamento dati',
              'Download dei file CSV in corso...', _currentProgress);
        }
      }
    }
  }

  // Carica le stazioni di benzina
  Future<void> _loadGasStations(double lat, double lng,
      [int radius = 5]) async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // Recuperiamo le stazioni passando anche il radius
      final stations = await _service.getGasStations(lat, lng, radius);

      // Chiudiamo ogni dialog aperto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (stations.isEmpty && mounted) {
        // Se non ci sono stazioni, mostro un messaggio più specifico
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Nessun distributore trovato nei dati CSV. Verifica che il download dei file sia stato completato con successo.'),
            duration: Duration(seconds: 6),
          ),
        );

        // Chiediamo all'utente se vuole riprovare
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nessuna stazione trovata'),
            content:
                const Text('Vuoi tentare un download forzato dei dati CSV?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _showStatusDialog('Aggiornamento',
                      'Download forzato dei dati CSV in corso...');
                  final success = await _service.robustForceUpdate();
                  if (success) {
                    // Riprova dopo il download
                    _initializeWithPosition();
                  } else {
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Download fallito. Per favore riprova più tardi.')),
                      );
                    }
                  }
                },
                child: const Text('Sì'),
              ),
            ],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _stations = stations;
          _markers = _createMarkersFromStations(stations);
          _isLoading = false;
        });

        // Mostra un riepilogo dei risultati solo se ci sono stazioni
        if (stations.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Trovati ${stations.length} distributori nei dati CSV'),
              duration: const Duration(seconds: 3),
            ),
          );

          // Centra la mappa sulle stazioni trovate
          _fitMapToBounds(stations);
        }
      }
    } catch (e) {
      // Chiudi eventuali dialoghi aperti
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Riprova',
              onPressed: () => _initializeWithPosition(),
            ),
          ),
        );
      }
    }
  }

  // Metodo per centrare la mappa sulle stazioni trovate
  void _fitMapToBounds(List<GasStation> stations) {
    if (stations.isEmpty || _mapController == null) return;

    try {
      // Calcola i limiti che contengono tutte le stazioni
      double minLat = 90.0;
      double maxLat = -90.0;
      double minLng = 180.0;
      double maxLng = -180.0;

      // Aggiungi la posizione corrente
      minLat = min(minLat, _currentPosition.latitude);
      maxLat = max(maxLat, _currentPosition.latitude);
      minLng = min(minLng, _currentPosition.longitude);
      maxLng = max(maxLng, _currentPosition.longitude);

      // Aggiungi tutte le stazioni
      for (final station in stations) {
        minLat = min(minLat, station.latitude);
        maxLat = max(maxLat, station.latitude);
        minLng = min(minLng, station.longitude);
        maxLng = max(maxLng, station.longitude);
      }

      // Crea i limiti
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Centra la mappa con un po' di padding
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    } catch (e) {
      logError('Errore nel centrare la mappa: $e');

      // Fallback: centra sulla posizione attuale
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 12),
        ),
      );
    }
  }

  // Metodo per mostrare lo stato dell'applicazione
  void _showStatusDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Metodo per creare markers dalle stazioni
  Set<Marker> _createMarkersFromStations(List<GasStation> stations) {
    final Set<Marker> markers = stations.map((station) {
      // Calcoliamo il colore del marker in base al prezzo
      BitmapDescriptor markerIcon;

      // Verifica se ha un prezzo per la benzina
      final price = station.fuelPrices['Benzina'];
      if (price != null) {
        // Determina il colore in base al prezzo
        if (price < 1.8) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else if (price < 2.0) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
        } else {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        }
      } else {
        // Se non c'è prezzo per la benzina, usa il colore predefinito
        markerIcon = BitmapDescriptor.defaultMarker;
      }

      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: station.name,
          snippet:
              'Benzina: €${station.fuelPrices["Benzina"]?.toStringAsFixed(3) ?? "N/D"}',
        ),
        onTap: () => _showStationDetails(station),
      );
    }).toSet();

    // Aggiungi marker per posizione corrente
    markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: _currentPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
                        _buildFuelPriceRow(
                            'Benzina', station.fuelPrices['Benzina']),
                        const Divider(),
                        _buildFuelPriceRow(
                            'Diesel', station.fuelPrices['Diesel']),
                        const Divider(),
                        _buildFuelPriceRow('GPL', station.fuelPrices['GPL']),
                        if (station.fuelPrices.containsKey('Metano')) ...[
                          const Divider(),
                          _buildFuelPriceRow(
                              'Metano', station.fuelPrices['Metano']),
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
  Widget _buildFuelPriceRow(String fuelType, double? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fuelType),
        Text(
          price != null ? '€${price.toStringAsFixed(3)}' : 'N/D',
          style: const TextStyle(fontWeight: FontWeight.bold),
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

  // Nuovo metodo per diagnosticare e riparare problemi CSV
  Future<void> _diagnosticCsvFiles() async {
    if (!mounted) return;

    _showStatusDialog('Diagnostica', 'Analisi dei file CSV in corso...');

    try {
      final debugInfo = await _service.debugCsvFiles();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCsvDiagnosticResults(debugInfo);
    } catch (e) {
      logError('Errore durante la diagnostica: $e');

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore diagnostica: $e')),
      );
    }
  }

  // Mostra i risultati della diagnostica
  void _showCsvDiagnosticResults(Map<String, dynamic> debugInfo) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnostica File CSV'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'File esistenti: ${debugInfo['filesExist'] ? 'Sì' : 'No'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: debugInfo['filesExist'] ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text('File stazioni:'),
              SelectableText('${debugInfo['stationsPath']}',
                  style: const TextStyle(fontSize: 12)),
              Text(
                  'Dimensione: ${_formatFileSize(debugInfo['stationsSize'] ?? 0)}'),
              const SizedBox(height: 8),
              Text('File prezzi:'),
              SelectableText('${debugInfo['pricesPath']}',
                  style: const TextStyle(fontSize: 12)),
              Text(
                  'Dimensione: ${_formatFileSize(debugInfo['pricesSize'] ?? 0)}'),
              const SizedBox(height: 16),
              if (debugInfo['error']?.isNotEmpty ?? false)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Text('ERRORE: ${debugInfo['error']}',
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              const Text('Prima riga stazioni:'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  debugInfo['stationsFirstLine'] ?? 'Nessun dato',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Prima riga prezzi:'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  debugInfo['pricesFirstLine'] ?? 'Nessun dato',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _repairCsvFiles();
            },
            child: const Text('Ripara file CSV'),
          ),
        ],
      ),
    );
  }

  // Formatta la dimensione del file
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Tenta di riparare i file CSV
  Future<void> _repairCsvFiles() async {
    _showStatusDialog(
        'Riparazione', 'Tentativo di riparazione file CSV in corso...');

    try {
      final success = await _service.repairCsvFiles();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Riparazione completata. Ricaricamento dati...')),
        );

        // Ricarica i dati dopo la riparazione
        _initializeWithPosition();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile riparare i file CSV')),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
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
            onPressed: _initializeWithPosition,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import_csv') {
                _navigateToImportCSV();
              } else if (value == 'show_first_10') {
                _showFirst10Stations();
              } else if (value == 'view_csv') {
                _navigateToCsvViewer();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Importa CSV manuale'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'show_first_10',
                child: Row(
                  children: [
                    Icon(Icons.view_list),
                    SizedBox(width: 8),
                    Text('Mostra 10 stazioni'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_csv',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Visualizza file CSV'),
                  ],
                ),
              ),
            ],
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
                // Dropdown per selezionare il veicolo
                if (_vehicles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<Vehicle>(
                      value: _selectedVehicle,
                      items: _vehicles.map((Vehicle vehicle) {
                        return DropdownMenuItem<Vehicle>(
                          value: vehicle,
                          child: Text('${vehicle.brand} ${vehicle.model}'),
                        );
                      }).toList(),
                      onChanged: (Vehicle? newValue) {
                        setState(() {
                          _selectedVehicle = newValue;
                          // Aggiorna i dati in base al veicolo selezionato
                        });
                      },
                    ),
                  ),
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

  // Metodo migliorato per mostrare le prime 10 stazioni
  void _showFirst10Stations() async {
    if (!mounted) return;

    try {
      _showStatusDialog(
          'Caricamento', 'Recupero delle stazioni dal CSV senza filtri...');

      // Verifica che il servizio sia disponibile
      // ignore: unnecessary_null_comparison
      if (_service == null) {
        throw Exception('Servizio non inizializzato');
      }

      // Utilizza il metodo corretto per ottenere le prime 10 stazioni
      final stations = await _service.getFirst10StationsFromCSV();

      // Chiudi il dialogo di stato
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (stations.isEmpty) {
        logInfo('Nessuna stazione trovata nel file CSV');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Nessuna stazione trovata nel file CSV. Potrebbero esserci problemi con il formato del file o il download non è riuscito.'),
              duration: Duration(seconds: 8),
            ),
          );

          // Mostra opzioni di risoluzione
          _showCsvTroubleshootingDialog();
        }
        return;
      }

      logInfo('Trovate ${stations.length} stazioni senza filtro');

      // Log dettagli delle stazioni trovate
      for (int i = 0; i < min(3, stations.length); i++) {
        final s = stations[i];
        logInfo(
            'STAZIONE $i: ${s.id} | ${s.name} | (${s.latitude}, ${s.longitude})');
      }

      // Aggiorna lo stato con le stazioni trovate
      if (mounted) {
        setState(() {
          _stations = stations;
          _markers = _createMarkersFromStations(stations);
        });

        // Mostra i dettagli delle stazioni trovate
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${stations.length} stazioni trovate dal CSV'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'I dati sono stati caricati con successo senza applicare filtri di distanza.'),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(5, stations.length),
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(station.name),
                          subtitle: Text(station.address),
                          trailing: station.fuelPrices.containsKey('Benzina')
                              ? Text(
                                  '€ ${station.fuelPrices['Benzina']!.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                              : const Text('N/D'),
                          onTap: () => _selectStation(station),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _initializeWithPosition(); // Ricarica i dati normalmente
                },
                child: const Text('Ricarica tutti i dati'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      logError('Errore recupero stazioni senza filtro: $e');

      if (mounted) {
        // Chiudi il dialogo di caricamento se aperto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Mostra un messaggio di errore più dettagliato
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento: ${e.toString()}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dettagli',
              onPressed: () => _showDebugErrorDialog(e),
            ),
          ),
        );
      }
    }
  }

  // Nuovo metodo per mostrare un dialogo di debug con informazioni sull'errore
  void _showDebugErrorDialog(dynamic error) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore di Debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Si è verificato un errore durante il caricamento dei dati:'),
              const SizedBox(height: 12),
              Text('${error.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Suggerimenti:'),
              const Text('• Verifica la connessione internet'),
              const Text('• Controlla che i file CSV siano disponibili'),
              const Text('• Riavvia l\'applicazione'),
              const SizedBox(height: 20),
              const Text('Info tecniche:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Tipo errore: ${error.runtimeType}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeWithPosition(); // Riprova a caricare i dati
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  // Metodo per forzare download con ritardo
  void _forceCsvDownloadWithDelay() async {
    _showProgressDialog(
        'Download forzato', 'Preparazione download dei file CSV...', 0.0);

    // Piccolo ritardo per assicurarsi che ogni operazione precedente sia terminata
    await Future.delayed(const Duration(seconds: 2));

    // Correzione dell'errore di tipo qui
    _service.setDownloadProgressCallback((progress) {
      _updateProgressDialog(progress);
    });

    try {
      await _service.forceUpdate();

      // Chiudi il dialogo di progresso
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Riprova a caricare i dati
      _initializeWithPosition();
    } catch (e) {
      // Chiudi il dialogo di progresso
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download fallito: ${e.toString()}'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      _service.clearDownloadProgressCallback();
    }
  }

  // Nuovo metodo per mostrare dialogo di risoluzione problemi CSV
  void _showCsvTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Problemi con i file CSV'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Possibili cause:'),
              const SizedBox(height: 8),
              const Text('• Il download dei file CSV è fallito'),
              const Text('• I file CSV sono vuoti o danneggiati'),
              const Text('• Il formato dei file CSV è cambiato'),
              const Text('• Non ci sono permessi di scrittura'),
              const SizedBox(height: 16),
              const Text('Azioni da provare:'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Forza download completo'),
                onPressed: () {
                  Navigator.pop(context);
                  _forceCsvDownloadWithDelay();
                },
              ),
              const SizedBox(height: 8),
              // Aggiungiamo il nuovo pulsante per la diagnostica
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Esegui diagnostica'),
                onPressed: () {
                  Navigator.pop(context);
                  _diagnosticCsvFiles();
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Verifica URL CSV'),
                onPressed: () {
                  _launchCsvUrls();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // Metodo per aprire gli URL dei CSV
  void _launchCsvUrls() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL dei file CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File stazioni:'),
            SelectableText(
                'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv',
                style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 8),
            ElevatedButton(
              child: const Text('Apri URL stazioni'),
              onPressed: () async {
                final url = Uri.parse(
                    'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('File prezzi:'),
            SelectableText(
                'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv',
                style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 8),
            ElevatedButton(
              child: const Text('Apri URL prezzi'),
              onPressed: () async {
                final url = Uri.parse(
                    'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // Metodo per navigare alla pagina di importazione CSV
  void _navigateToImportCSV() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCsvPage(
          onFilesImported: () {
            // Ricarica i dati dopo l'importazione
            _initializeWithPosition();
          },
        ),
      ),
    );
  }

  // Metodo per navigare alla pagina di visualizzazione CSV
  void _navigateToCsvViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CsvViewerPage(),
      ),
    );
  }
}
