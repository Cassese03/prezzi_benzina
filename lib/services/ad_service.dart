import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    const String admobBannerKey = String.fromEnvironment('ADMOB_BANNER_KEY');
    return dotenv.env['ADMOB_BANNER_KEY'] ?? admobBannerKey;
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner caricato correttamente');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner fallito nel caricamento: ${error.message}');
          ad.dispose();
        },
        onAdOpened: (ad) => print('Banner aperto'),
        onAdClosed: (ad) => print('Banner chiuso'),
        onAdImpression: (ad) => print('Banner impression'),
        onAdWillDismissScreen: (ad) => print('Banner will dismiss'),
        onPaidEvent: (ad, value, precision, currencyCode) =>
            print('Banner paid event: $value $currencyCode'),
      ),
    );
  }

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();

      // Configurazione con il tuo ID dispositivo reale
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            'CC0B33DBD53E40530019ED5C8EF53418', // Il tuo ID dispositivo reale
          ],
        ),
      );

      print('Mobile Ads inizializzato con successo');
    } catch (e) {
      print('Errore nell\'inizializzazione di Mobile Ads: $e');
    }
  }
}
