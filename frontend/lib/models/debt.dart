class Debt {
  final String id;
  final String consumerName;
  final List<DebtItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? branchId;
  final String? businessId;

  Debt({
    required this.id,
    required this.consumerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.branchId,
    this.businessId,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      consumerName: json['consumerName'],
      items: (json['items'] as List)
          .map((i) => DebtItem.fromJson(i))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      branchId: json['branch'] != null ? json['branch']['id'] : null,
      businessId: json['business'] != null ? json['business']['id'] : null,
    );
  }
}

class DebtItem {
  final String id;
  final String name;
  final String productCode;
  final int quantity;
  final double price;

  DebtItem({
    required this.id,
    required this.name,
    required this.productCode,
    required this.quantity,
    required this.price,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['id'],
      name: json['name'],
      productCode: json['productCode'],
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}
