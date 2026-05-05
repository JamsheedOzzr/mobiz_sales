import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'invoice_create_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.session,
    required this.api,
    required this.customer,
  });

  final UserSession session;
  final ApiService api;
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 
                       kToolbarHeight - 
                       MediaQuery.paddingOf(context).top - 
                       MediaQuery.paddingOf(context).bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 14),
                  child: Text(
                    customer.name.toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ImagePlaceholder(size: 150),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _InfoLine(icon: Icons.location_on, text: customer.address),
                            _InfoLine(icon: Icons.phone, text: customer.contact),
                            _InfoLine(icon: Icons.email, text: customer.email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Text(
                    'Customer Type: ${customer.type.toUpperCase()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 40),
                const Spacer(),
                Center(
                  child: PurpleActionTile(
                    icon: Icons.point_of_sale,
                    label: 'Sale',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvoiceCreateScreen(
                          session: session,
                          api: api,
                          customer: customer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text(text.isEmpty ? '-' : text, style: const TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}
