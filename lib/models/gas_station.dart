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
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    Map<String, PriceInfo> prices = {};

    try {
      final prezziCarburanti = json['prezzi_carburanti'] as List;
      for (var prezzo in prezziCarburanti) {
        final tipo = prezzo['tipo'] as String;
        final isSelf = prezzo['self_service'] as bool;

        // Gestione sicura del parsing del prezzo
        double price;
        final rawPrice = prezzo['prezzo'];
        if (rawPrice is double) {
          price = rawPrice;
        } else if (rawPrice is int) {
          price = rawPrice.toDouble();
        } else {
          price = double.tryParse(rawPrice.toString()) ?? 0.0;
        }

        final updateStr = prezzo['ultimo_aggiornamento'] as String;

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
    } catch (e) {
      //print('Errore dettagliato nel parsing prezzi: $e');
    }

    return GasStation(
      id: json['id_stazione'],
      name: json['bandiera'] ?? '',
      gestore: json['dettagli_stazione']['gestore'] ?? '',
      tipo: json['dettagli_stazione']['tipo'] ?? '',
      latitude: json['maps']['lat'].toDouble(),
      longitude: json['maps']['lon'].toDouble(),
      address: json['indirizzo']['via'] ?? '',
      comune: json['indirizzo']['comune'] ?? '',
      provincia: json['indirizzo']['provincia'] ?? '',
      fuelPrices: prices,
    );
  }

  static DateTime _parseDateTime(String dateStr) {
    final parts = dateStr.split(' ');
    final dateParts = parts[0].split('/');
    final timeParts = parts[1].split(':');

    return DateTime(
      int.parse(dateParts[2]), // anno
      int.parse(dateParts[1]), // mese
      int.parse(dateParts[0]), // giorno
      int.parse(timeParts[0]), // ora
      int.parse(timeParts[1]), // minuti
      int.parse(timeParts[2]), // secondi
    );
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

  PriceInfo({
    required this.servito,
    required this.self,
    required this.lastUpdate,
  });
}
