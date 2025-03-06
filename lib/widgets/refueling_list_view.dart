import 'package:flutter/material.dart';
import '../models/refueling.dart';
import 'package:intl/intl.dart';

class RefuelingListView extends StatelessWidget {
  final List<Refueling> refuelings;
  final Function(Refueling) onTap;

  const RefuelingListView({
    Key? key,
    required this.refuelings,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (refuelings.isEmpty) {
      return const Center(
        child: Text('Nessun rifornimento registrato'),
      );
    }

    return ListView.builder(
      itemCount: refuelings.length,
      itemBuilder: (context, index) {
        final refueling = refuelings[index];
        final date = DateFormat('dd/MM/yyyy').format(refueling.date);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () => onTap(refueling),
            leading: const Icon(Icons.local_gas_station),
            title: Text(date),
            subtitle: Text('€${refueling.totalAmount.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${refueling.liters.toStringAsFixed(2)}L'),
                Text('${refueling.consumption.toStringAsFixed(1)}L/100km'),
              ],
            ),
          ),
        );
      },
    );
  }
}
