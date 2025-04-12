class GasStation {
  final String id;
  final String name;
  final String gestore;
  final String tipo;
  final double latitude;
  final double longitude;
  final String address;
  final String comune;
  final String provincia;
  final Map<String, PriceInfo> fuelPrices;
  final double distanza; // Nuovo campo per la distanza

  GasStation({
    required this.id,
    required this.name,
    required this.gestore,
    required this.tipo,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.comune,
    required this.provincia,
    required this.fuelPrices,
    required this.distanza, // Aggiunto al costruttore
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    Map<String, PriceInfo> prices = {};

    try {
      final prezziCarburanti = json['prezzi_carburanti'] as List;
      for (var prezzo in prezziCarburanti) {
        final tipo = prezzo['tipo'] as String;
        final isSelf = prezzo['self_service'] as bool? ?? true;

        // Gestione sicura del parsing del prezzo
        double price;
        final rawPrice = prezzo['prezzo'] ?? 0.0;
        if (rawPrice is double) {
          price = rawPrice;
        } else if (rawPrice is int) {
          price = rawPrice.toDouble();
        } else {
          price = double.tryParse(rawPrice.toString()) ?? 0.0;
        }

        final updateStr = prezzo['ultimo_aggiornamento'] as String;

        if (json['tipo_stazione'] == 'Elettrica') {
          prices['Elettrica'] = PriceInfo(
            servito: 0.0,
            self: 0.0,
            lastUpdate: _parseDateTime(updateStr),
            potenzaKw: prezzo['potenza_kw'] as int?,
            unitaMisura: prezzo['unita_misura'] as String?,
            tipo: tipo,
          );
        } else if (json['tipo_stazione'] == 'Benzina') {
          // Gestione specifica per stazioni di benzina
          if (!prices.containsKey(tipo)) {
            prices[tipo] = PriceInfo(
              servito: isSelf ? 0.0 : price,
              self: isSelf ? price : 0.0,
              lastUpdate: _parseDateTime(updateStr),
            );
          } else {
            if (isSelf) {
              prices[tipo]!.self = price;
            } else {
              prices[tipo]!.servito = price;
            }
          }
        }
      }
    } catch (e) {
      print('Errore dettagliato nel parsing prezzi: $e');
    }

    return GasStation(
      id: json['id_stazione'],
      name: json['dettagli_stazione']['nome'] ?? '',
      gestore: json['dettagli_stazione']['gestore'] ?? '',
      tipo: json['dettagli_stazione']['tipo'] ?? '',
      latitude: json['maps']['lat'].toDouble(),
      longitude: json['maps']['lon'].toDouble(),
      address: json['indirizzo']['via'] ?? '',
      comune: json['indirizzo']['comune'] ?? '',
      provincia: json['indirizzo']['provincia'] ?? '',
      fuelPrices: prices,
      distanza: json['distanza'].toDouble(), // Parsing della distanza
    );
  }

  static DateTime _parseDateTime(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length < 2) return DateTime.now();

      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      if (dateParts.length < 3 || timeParts.length < 3) return DateTime.now();

      return DateTime(
        int.parse(dateParts[2]), // anno
        int.parse(dateParts[1]), // mese
        int.parse(dateParts[0]), // giorno
        int.parse(timeParts[0]), // ora
        int.parse(timeParts[1]), // minuti
        int.parse(timeParts[2]), // secondi
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  double? getLowestPrice(String fuelType, {bool selfServiceOnly = true}) {
    final price = fuelPrices[fuelType];
    if (price == null) return null;
    return selfServiceOnly && price.self > 0 ? price.self : price.servito;
  }
}

class PriceInfo {
  double servito;
  double self;
  DateTime lastUpdate;
  int? potenzaKw; // Solo per stazioni elettriche
  String? unitaMisura; // Solo per stazioni elettriche
  String? tipo; // Tipo di carburante o elettricità

  PriceInfo({
    required this.servito,
    required this.self,
    required this.lastUpdate,
    this.potenzaKw,
    this.unitaMisura,
    this.tipo,
  });
}
