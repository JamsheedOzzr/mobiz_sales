import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key, required this.session, required this.api});

  final UserSession session;
  final ApiService api;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late Future<List<Invoice>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.api.getVanSales(
      userId: widget.session.userId,
      storeId: widget.session.storeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Invoice')),
      body: FutureBuilder<List<Invoice>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(message: snapshot.error.toString(), onRetry: () => setState(_load));
          }
          final invoices = (snapshot.data ?? []).where((invoice) {
            final text = '${invoice.number} ${invoice.customerName} ${invoice.date}'.toLowerCase();
            return text.contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              SearchField(onChanged: (value) => setState(() => _query = value), hint: 'Search invoice'),
              Expanded(
                child: invoices.isEmpty
                    ? const EmptyState(message: 'No invoices found')
                    : ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return TileCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${invoice.number} | ${invoice.date}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    invoice.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  Text('Total: ${invoice.total.toStringAsFixed(2)}'),
                                  const SizedBox(height: 12),
                                  Text('Round off:${invoice.roundOff.toStringAsFixed(2)}'),
                                  const SizedBox(height: 12),
                                  Text('Total Vat: ${invoice.totalTax.toStringAsFixed(2)}'),
                                  Text('Grand Total: ${invoice.grandTotal.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
