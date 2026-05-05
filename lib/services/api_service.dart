import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entities.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static const _baseUrl = 'http://142.93.214.133:3641/api';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<UserSession> login(String email, String password) async {
    final json = await _post('/login', {'email': email, 'password': password});
    final data = _unwrap(json);
    final userId = _readInt(data, ['user_id', 'id'], fallback: 150);
    Map<String, dynamic> detail;
    try {
      detail = await getUserDetail(userId);
    } catch (_) {
      detail = data is Map<String, dynamic> ? data : <String, dynamic>{};
    }
    return UserSession(
      userId: userId,
      storeId: _readInt(detail, ['store_id'], fallback: 112),
      routeId: _readInt(detail, ['route_id'], fallback: 84),
      name: _readString(detail, ['name', 'username', 'email'], fallback: 'Sales'),
      raw: detail,
    );
  }

  Future<Map<String, dynamic>> getUserDetail(int userId) async {
    final json = await _get('/get_user_detail', {'user_id': '$userId'});
    final data = _unwrap(json);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Customer>> getCustomers({
    required int routeId,
    required int storeId,
  }) async {
    final json = await _get('/get_customer', {
      'route_id': '$routeId',
      'store_id': '$storeId',
    });
    return _listFrom(json).map(_customerFromJson).toList();
  }

  Future<List<Product>> getProducts({required int storeId}) async {
    final json = await _get('/get_product', {'store_id': '$storeId'});
    return _listFrom(json).map(_productFromJson).toList();
  }

  Future<List<ProductType>> getProductTypes() async {
    final json = await _get('/get_product_type');
    return _listFrom(json).map((item) {
      return ProductType(
        id: _readInt(item, ['id', 'product_type_id'], fallback: 1),
        name: _readString(item, ['name', 'type', 'product_type'], fallback: 'Normal'),
      );
    }).toList();
  }

  Future<Product> getProductDetail(int productId) async {
    final json = await _get('/get_product_detail', {'product_id': '$productId'});
    final data = _unwrap(json);
    if (data is Map<String, dynamic>) return _productFromJson(data);
    throw ApiException('Product details not found');
  }

  Future<void> createVanSale({
    required UserSession session,
    required Customer customer,
    required List<CartItem> items,
    required bool ifVat,
    required double discount,
    required String remarks,
  }) async {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    final taxable = (total - discount).clamp(0, double.infinity).toDouble();
    final tax = ifVat ? taxable * 0.05 : 0.0;
    final grandBeforeRound = taxable + tax;
    final grandTotal = grandBeforeRound.roundToDouble();
    final roundOff = grandTotal - grandBeforeRound;

    await _post('/vansale.store', {
      'customer_id': customer.id,
      'store_id': session.storeId,
      'user_id': session.userId,
      'van_id': 0,
      'save_mode': 'normal',
      'order_type': 1,
      'discount': _money(discount),
      'total': _money(total),
      'total_tax': _money(tax),
      'grand_total': _money(grandTotal),
      'round_off': _money(roundOff),
      'if_vat': ifVat ? 1 : 0,
      'remarks': remarks.isEmpty ? 'POS Sale' : remarks,
      'item_id': items.map((e) => e.product.id).toList(),
      'quantity': items.map((e) => e.quantity).toList(),
      'mrp': items.map((e) => _money(e.rate)).toList(),
      'product_type': items.map((e) => e.productTypeId).toList(),
      'unit': items.map((e) => e.unitId).toList(),
    });
  }

  Future<List<Invoice>> getVanSales({
    required int userId,
    required int storeId,
  }) async {
    final json = await _get('/vansale.index', {
      'user_id': '$userId',
      'store_id': '$storeId',
      'van_id': '0',
    });
    return _listFrom(json).map(_invoiceFromJson).toList();
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers);
    return _decode(response);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  dynamic _decode(http.Response response) {
    final body = response.body.trim();
    dynamic json;
    try {
      json = body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      throw ApiException('Invalid server response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_readString(json, ['message', 'error'], fallback: 'Request failed'));
    }
    if (json is Map<String, dynamic>) {
      final ok = json['status'];
      if (ok == false || ok == 'false') {
        throw ApiException(_readString(json, ['message', 'error'], fallback: 'Request failed'));
      }
    }
    return json;
  }

  dynamic _unwrap(dynamic json) {
    if (json is Map<String, dynamic>) {
      for (final key in ['data', 'result', 'user', 'customer', 'product']) {
        if (json[key] != null) return json[key];
      }
    }
    return json;
  }

  List<Map<String, dynamic>> _listFrom(dynamic json) {
    final data = _unwrap(json);
    dynamic list = data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'list', 'items', 'products', 'customers', 'invoices']) {
        if (data[key] is List) list = data[key];
      }
      if (list == data) {
        for (final value in data.values) {
          if (value is List) {
            list = value;
            break;
          }
        }
      }
    }
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Customer _customerFromJson(Map<String, dynamic> json) {
    return Customer(
      id: _readInt(json, ['id', 'customer_id'], fallback: 0),
      name: _readString(json, ['name', 'customer_name', 'shop_name'], fallback: 'Customer'),
      address: _readString(json, ['address', 'location'], fallback: ''),
      contact: _readString(json, ['contact', 'mobile', 'phone'], fallback: ''),
      email: _readString(json, ['email'], fallback: ''),
      type: _readString(json, ['customer_type', 'type'], fallback: 'CASH'),
      raw: json,
    );
  }

  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: _readInt(json, ['id', 'product_id', 'item_id'], fallback: 0),
      code: _readString(json, ['code', 'product_code', 'item_code'], fallback: ''),
      name: _readString(json, ['name', 'product_name', 'item_name'], fallback: 'Product'),
      price: _readDouble(json, ['mrp', 'price', 'rate', 'amount'], fallback: 0),
      unitId: _readInt(json, ['unit_id', 'unit'], fallback: 1530),
      unitName: _readString(json, ['unit_name', 'unit'], fallback: 'PCS'),
      productTypeId: _readInt(json, ['product_type_id', 'product_type'], fallback: 1),
      productTypeName: _readString(json, ['product_type_name', 'type'], fallback: 'Normal'),
      raw: json,
    );
  }

  Invoice _invoiceFromJson(Map<String, dynamic> json) {
    return Invoice(
      number: _readString(json, ['invoice_no', 'number', 'sale_no', 'code'], fallback: 'Sale'),
      date: _readString(json, ['date', 'created_at', 'invoice_date'], fallback: ''),
      customerName: _readString(json, ['customer_name', 'name'], fallback: 'Customer'),
      total: _readDouble(json, ['total'], fallback: 0),
      totalTax: _readDouble(json, ['total_tax', 'tax', 'vat'], fallback: 0),
      roundOff: _readDouble(json, ['round_off'], fallback: 0),
      grandTotal: _readDouble(json, ['grand_total', 'net_total'], fallback: 0),
      raw: json,
    );
  }

  static int _readInt(dynamic json, List<String> keys, {required int fallback}) {
    final value = _readValue(json, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static double _readDouble(dynamic json, List<String> keys, {required double fallback}) {
    final value = _readValue(json, keys);
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  static String _readString(dynamic json, List<String> keys, {required String fallback}) {
    final value = _readValue(json, keys);
    if (value == null || '$value'.trim().isEmpty || '$value' == 'null') return fallback;
    return '$value';
  }

  static dynamic _readValue(dynamic json, List<String> keys) {
    if (json is! Map) return null;
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
    return null;
  }

  String _money(double value) => value.toStringAsFixed(2);
}
