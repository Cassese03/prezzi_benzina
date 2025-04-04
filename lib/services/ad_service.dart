import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    // Usa l'ID di test per lo sviluppo
    return 'ca-app-pub-4250948562102925/8449028167';
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner caricato con successo');
        },
        onAdFailedToLoad: (ad, error) {
          print('Errore caricamento banner: ${error.message}');
          ad.dispose();
        },
      ),
    );
  }
}
