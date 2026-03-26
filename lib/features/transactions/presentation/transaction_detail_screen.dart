import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String id;

  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Center(child: Text('Transacción $id — próximamente')),
    );
  }
}
