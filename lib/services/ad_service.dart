import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kDebugMode) {
        // ID di test per sviluppo
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      // ID reale per produzione
      return 'ca-app-pub-4250948562102925/8449028167';
    }
    return '';
  }

  static Future<void> initialize() async {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      // Configurazione per test
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['CC0B33DBD53E40530019ED5C8EF53418'],
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
    }
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner caricato con successo'),
        onAdFailedToLoad: (ad, error) {
          print('Errore caricamento banner: ${error.message}');
          ad.dispose();
        },
      ),
    );
  }
}
