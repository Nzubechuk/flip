class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? productCode;
  final String? upc;
  final String? ean13;
  final String branchId;
  final String? branchName;
  final String? category;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.productCode,
    this.upc,
    this.ean13,
    required this.branchId,
    this.branchName,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      productCode: json['productCode'],
      upc: json['upc'],
      ean13: json['ean13'],
      branchId: json['branchId'] ?? '',
      branchName: json['branchName'],
      category: json['category'],
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? productCode,
    String? upc,
    String? ean13,
    String? branchId,
    String? branchName,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      productCode: productCode ?? this.productCode,
      upc: upc ?? this.upc,
      ean13: ean13 ?? this.ean13,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'branchId': branchId.isEmpty ? null : branchId,
      'productCode': productCode,
      'upc': upc,
      'ean13': ean13,
      'category': category,
    };
  }
}

class BarcodeProductInfo {
  final String barcode;
  final String? title;
  final String? description;
  final String? brand;
  final String? model;
  final String? category;
  final String? imageUrl;
  final double? suggestedPrice;

  BarcodeProductInfo({
    required this.barcode,
    this.title,
    this.description,
    this.brand,
    this.model,
    this.category,
    this.imageUrl,
    this.suggestedPrice,
  });

  factory BarcodeProductInfo.fromJson(Map<String, dynamic> json) {
    return BarcodeProductInfo(
      barcode: json['barcode'] ?? '',
      title: json['title'],
      description: json['description'],
      brand: json['brand'],
      model: json['model'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      suggestedPrice: json['suggestedPrice'] != null
          ? (json['suggestedPrice'] as num).toDouble()
          : null,
    );
  }
}




