import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/entities.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'product_list_screen.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({
    super.key,
    required this.session,
    required this.api,
    required this.customer,
  });

  final UserSession session;
  final ApiService api;
  final Customer customer;

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final _remarks = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final List<CartItem> _items = [];
  bool _vat = true;
  bool _saving = false;

  @override
  void dispose() {
    _remarks.dispose();
    _discount.dispose();
    super.dispose();
  }

  double get _discountValue => double.tryParse(_discount.text) ?? 0;
  double get _total => _items.fold(0, (sum, item) => sum + item.amount);
  double get _taxable => (_total - _discountValue).clamp(0, double.infinity).toDouble();
  double get _tax => _vat ? _taxable * 0.05 : 0;
  double get _grandBeforeRound => _taxable + _tax;
  double get _grandTotal => _grandBeforeRound.roundToDouble();
  double get _roundOff => _grandTotal - _grandBeforeRound;

  Future<void> _selectProduct() async {
    final item = await Navigator.of(context).push<CartItem>(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(api: widget.api, storeId: widget.session.storeId),
      ),
    );
    if (item != null) setState(() => _items.add(item));
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      showSnack(context, 'Select at least one product');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createVanSale(
        session: widget.session,
        customer: widget.customer,
        items: _items,
        ifVat: _vat,
        discount: _discountValue,
        remarks: _remarks.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Invoice saved successfully');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: _selectProduct)],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.customer.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  _ToggleButton(label: 'VAT', selected: _vat, onTap: () => setState(() => _vat = true)),
                  _ToggleButton(label: 'NO VAT', selected: !_vat, onTap: () => setState(() => _vat = false)),
                ],
              ),
            ),
          ),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(message: 'Tap the search icon to select products', onRetry: _selectProduct),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _items[index];
                  return TileCard(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${item.productTypeName} | ${item.unitName} | Qty: ${item.quantity} | Rate: ${item.rate.toStringAsFixed(3)} | Amt: ${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _items.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(78, 8, 28, 4),
                  child: Row(
                    children: [
                      const Text('Remarks'),
                      const SizedBox(width: 8),
                      Expanded(child: SizedBox(height: 38, child: TextField(controller: _remarks))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(78, 6, 28, 4),
                  child: Row(
                    children: [
                      const Text('Discount'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _discount,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 6, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TotalLine(label: 'Total', value: _total),
                      _TotalLine(label: 'Tax', value: _tax),
                      _TotalLine(label: 'Round off', value: _roundOff),
                      _TotalLine(label: 'Grand Total', value: _grandTotal),
                      const SizedBox(height: 18),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('SAVE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black)),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${value.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 20, height: 1.35),
    );
  }
}
