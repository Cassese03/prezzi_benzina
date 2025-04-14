import 'package:flutter/material.dart';

class ProgressDialog extends StatefulWidget {
  final String title;
  final String message;
  final double progress;
  final bool showPercentage;

  const ProgressDialog({
    super.key,
    required this.title,
    required this.message,
    required this.progress,
    this.showPercentage = true,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Colors.grey[300],
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          if (widget.showPercentage) ...[
            const SizedBox(height: 16),
            Text('${(widget.progress * 100).toInt()}%'),
          ],
          const SizedBox(height: 8),
          Text(widget.message),
        ],
      ),
    );
  }
}

// Helper method to show the dialog easily
Future<void> showProgressDialog({
  required BuildContext context,
  required String title,
  required String message,
  required double progress,
  bool showPercentage = true,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ProgressDialog(
        title: title,
        message: message,
        progress: progress,
        showPercentage: showPercentage,
      );
    },
  );
}

// Helper method to update the dialog progress
void updateProgressDialog({
  required BuildContext context,
  required double progress,
}) {
  Navigator.of(context).pop();
  showProgressDialog(
    context: context,
    title: 'Scaricamento dati',
    message: 'Download dei file CSV in corso...',
    progress: progress,
  );
}
