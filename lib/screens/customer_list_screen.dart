import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, required this.session, required this.api});

  final UserSession session;
  final ApiService api;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late Future<List<Customer>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.api.getCustomers(
      routeId: widget.session.routeId,
      storeId: widget.session.storeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => showSnack(context, 'Add customer is not part of this assignment')),
        ],
      ),
      body: FutureBuilder<List<Customer>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(message: snapshot.error.toString(), onRetry: () => setState(_load));
          }
          final customers = (snapshot.data ?? []).where((customer) {
            final text = '${customer.name} ${customer.address} ${customer.contact}'.toLowerCase();
            return text.contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              SearchField(onChanged: (value) => setState(() => _query = value), hint: 'Search customer'),
              Expanded(
                child: customers.isEmpty
                    ? const EmptyState(message: 'No customers found')
                    : ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return TileCard(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(
                                  session: widget.session,
                                  api: widget.api,
                                  customer: customer,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const ImagePlaceholder(),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name.toUpperCase(),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Address:${customer.address}'),
                                      const SizedBox(height: 6),
                                      Text('Contact:${customer.contact}'),
                                    ],
                                  ),
                                ),
                              ],
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
