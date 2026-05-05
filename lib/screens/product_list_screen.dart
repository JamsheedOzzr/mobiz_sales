import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.api, required this.storeId});

  final ApiService api;
  final int storeId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.api.getProducts(storeId: widget.storeId);
  }

  Future<void> _openProduct(Product product) async {
    final detailed = await widget.api.getProductDetail(product.id).catchError((_) => product);
    if (!mounted) return;
    final item = await showDialog<CartItem>(
      context: context,
      builder: (_) => _ProductDialog(product: detailed),
    );
    if (item != null && mounted) Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copy Products')),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(message: snapshot.error.toString(), onRetry: () => setState(_load));
          }
          final products = (snapshot.data ?? []).where((product) {
            return product.title.toLowerCase().contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              SearchField(onChanged: (value) => setState(() => _query = value), hint: 'Search product'),
              Expanded(
                child: products.isEmpty
                    ? const EmptyState(message: 'No products found')
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return TileCard(
                            onTap: () => _openProduct(product),
                            child: Row(
                              children: [
                                const ImagePlaceholder(size: 64),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    product.title.toUpperCase(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({required this.product});

  final Product product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _quantity;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.product.price.toStringAsFixed(3));
    _quantity = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amount.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _save() {
    final qty = int.tryParse(_quantity.text) ?? 0;
    final rate = double.tryParse(_amount.text) ?? 0;
    if (qty <= 0 || rate <= 0) {
      showSnack(context, 'Enter valid quantity and amount');
      return;
    }
    Navigator.of(context).pop(
      CartItem(
        product: widget.product,
        quantity: qty,
        rate: rate,
        productTypeId: widget.product.productTypeId,
        productTypeName: widget.product.productTypeName,
        unitId: widget.product.unitId,
        unitName: widget.product.unitName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.product.title.toUpperCase(), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            const Center(child: ImagePlaceholder(size: 84)),
            const SizedBox(height: 24),
            _ReadonlyBox(label: 'Product Type', value: widget.product.productTypeName),
            const SizedBox(height: 10),
            _ReadonlyBox(label: 'Unit', value: widget.product.unitName),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 34),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.arrow_drop_down)),
      child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }
}
