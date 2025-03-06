class MapsService {
  static const String apiKey = 'MAPS-API-KEY';

  static String getStaticMapUrl(double lat, double lng,
      {int zoom = 15, int width = 400, int height = 200}) {
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=color:red%7C$lat,$lng'
        '&key=$apiKey';
  }

  static String getPlacePhotoUrl(double lat, double lng) {
    return 'https://maps.googleapis.com/maps/api/streetview?'
        'location=$lat,$lng'
        '&size=400x200'
        '&key=$apiKey';
  }
}
