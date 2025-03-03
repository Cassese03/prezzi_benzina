import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkLauncher extends StatelessWidget {
  final String url;
  final String title;
  final String? description;

  const LinkLauncher({
    Key? key,
    required this.url,
    required this.title,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 8),
            SelectableText(url, style: TextStyle(color: Colors.blue[800])),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Apri nel browser'),
              onPressed: () => _launchURL(context, url),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossibile aprire il link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.toString()}')),
        );
      }
    }
  }
}

// Widget per mostrare il dialogo dei link CSV
void showCsvLinksDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Link CSV del MISE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const LinkLauncher(
              title: 'File Stazioni',
              description: 'Anagrafica impianti attivi',
              url:
                  'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv',
            ),
            const LinkLauncher(
              title: 'File Prezzi',
              description: 'Prezzi aggiornati alle 8 del mattino',
              url: 'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    ),
  );
}
