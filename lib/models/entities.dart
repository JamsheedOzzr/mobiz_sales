class UserSession {
  UserSession({
    required this.userId,
    required this.storeId,
    required this.routeId,
    required this.name,
    this.raw = const {},
  });

  final int userId;
  final int storeId;
  final int routeId;
  final String name;
  final Map<String, dynamic> raw;
}

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.email,
    required this.type,
    this.raw = const {},
  });

  final int id;
  final String name;
  final String address;
  final String contact;
  final String email;
  final String type;
  final Map<String, dynamic> raw;
}

class Product {
  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.unitId,
    required this.unitName,
    required this.productTypeId,
    required this.productTypeName,
    this.raw = const {},
  });

  final int id;
  final String code;
  final String name;
  final double price;
  final int unitId;
  final String unitName;
  final int productTypeId;
  final String productTypeName;
  final Map<String, dynamic> raw;

  String get title {
    if (code.isEmpty) return name;
    return '$code | $name';
  }
}

class ProductType {
  ProductType({required this.id, required this.name});

  final int id;
  final String name;
}

class Invoice {
  Invoice({
    required this.number,
    required this.date,
    required this.customerName,
    required this.total,
    required this.totalTax,
    required this.roundOff,
    required this.grandTotal,
    this.raw = const {},
  });

  final String number;
  final String date;
  final String customerName;
  final double total;
  final double totalTax;
  final double roundOff;
  final double grandTotal;
  final Map<String, dynamic> raw;
}

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    required this.rate,
    required this.productTypeId,
    required this.productTypeName,
    required this.unitId,
    required this.unitName,
  });

  final Product product;
  int quantity;
  double rate;
  int productTypeId;
  String productTypeName;
  int unitId;
  String unitName;

  double get amount => quantity * rate;
}
