import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'customer_list_screen.dart';
import 'invoice_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.session, required this.api});

  final UserSession session;
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: Text('Hello ${session.name}'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.notifications))],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 
                       kToolbarHeight - 
                       MediaQuery.paddingOf(context).top - 
                       MediaQuery.paddingOf(context).bottom,
          ),
          child: IntrinsicHeight(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 42),
                  const Text(
                    'Mobiz Demo',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF3F3D91)),
                  ),
                  const Spacer(),
                  PurpleActionTile(
                    icon: Icons.people,
                    label: 'Customer',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CustomerListScreen(session: session, api: api)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PurpleActionTile(
                    icon: Icons.receipt_long,
                    label: 'Invoices',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InvoiceListScreen(session: session, api: api)),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
