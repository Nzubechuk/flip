class SaleItem {
  final String productId;
  final String? productCode;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final int stock;

  SaleItem({
    required this.productId,
    this.productCode,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.stock,
  });

  Map<String, dynamic> toJson() {
    return {
      'productCode': productCode ?? productId, // Backend expects productCode
      'quantity': quantity,
      'name': name,
      'price': price,
    };
  }
}

class Sale {
  final String id;
  final String? branchId;
  final double totalPrice;
  final DateTime saleDate;
  final List<String> items;

  Sale({
    required this.id,
    this.branchId,
    required this.totalPrice,
    required this.saleDate,
    required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['saleId'] ?? json['id'] ?? '',
      branchId: json['branchId'],
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      saleDate: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class ScannedProductRequest {
  final String productCode;
  final int quantity;

  ScannedProductRequest({
    required this.productCode,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'productCode': productCode,
      'quantity': quantity,
    };
  }
}

class SaleRequest {
  final List<SaleItem> items;

  SaleRequest({
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}




