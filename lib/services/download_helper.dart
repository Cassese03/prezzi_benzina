import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadHelper {
  // Controlla la connessione internet
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Controlla lo spazio disponibile
  static Future<int> getAvailableSpace() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();
      // Questo è un approccio approssimativo che potrebbe non funzionare su tutti i dispositivi
      return stat.size;
    } catch (e) {
      return -1;
    }
  }

  // Verifica che la directory sia scrivibile
  static Future<bool> isDirectoryWritable() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final testFile = File('${directory.path}/test_write.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verifica che un URL sia raggiungibile
  static Future<bool> isUrlReachable(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Timeout', 408),
          );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Download semplice con metodo alternativo
  static Future<bool> downloadFileSimple(String url, String localPath) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(minutes: 3),
          );

      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Esegue tutti i controlli diagnostici
  static Future<Map<String, bool>> runAllDiagnostics(List<String> urls) async {
    final results = <String, bool>{};

    results['internet'] = await checkInternetConnection();
    results['space'] = (await getAvailableSpace()) > 10 * 1024 * 1024; // 10 MB
    results['writable'] = await isDirectoryWritable();

    for (int i = 0; i < urls.length; i++) {
      results['url$i'] = await isUrlReachable(urls[i]);
    }

    return results;
  }
}
