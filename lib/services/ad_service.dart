import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // ID test
    } else {
      return 'admob-banner-key'; // ID reale
    }
  }

  static BannerAd createBannerAd() {
    final BannerAd banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          //print('Banner caricato CORRETTAMENTE');
        },
        onAdFailedToLoad: (ad, error) {
          //print('Banner ERRORE nel caricamento: ${error.message}');
          //print('Banner ERRORE codice: ${error.code}');
          //print('Banner ERRORE domain: ${error.domain}');
          ad.dispose();
        },
        //onAdOpened: (ad) => //print('Banner aperto'),
        //onAdClosed: (ad) => //print('Banner chiuso'),
        //onAdImpression: (ad) => //print('Banner impression'),
        //onAdWillDismissScreen: (ad) => //print('Banner will dismiss'),
        //onPaidEvent: (ad, value, precision, currencyCode) =>
        //print('Banner paid event: $value $currencyCode'),
      ),
    );

    banner.load();
    return banner;
  }

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();

      if (kDebugMode) {
        // Solo in modalità debug aggiungiamo gli ID dei dispositivi di test
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['CC0B33DBD53E40530019ED5C8EF53418'],
          ),
        );
        //print('Mobile Ads inizializzato in modalità TEST');
      } else {
        //print('Mobile Ads inizializzato in modalità PRODUZIONE');
      }
    } catch (e) {
      //print('ERRORE inizializzazione Mobile Ads: $e');
    }
  }
}
