class Business {
  final String id;
  final String name;
  final String? businessRegNumber;
  final String ceoId;

  Business({
    required this.id,
    required this.name,
    this.businessRegNumber,
    required this.ceoId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    // Handle UUID conversion - backend returns UUID as string
    String businessId = '';
    if (json['businessId'] != null) {
      businessId = json['businessId'].toString().trim();
    } else if (json['id'] != null) {
      businessId = json['id'].toString().trim();
    }
    
    String ceoId = '';
    if (json['ceoId'] != null) {
      ceoId = json['ceoId'].toString().trim();
    }
    
    final businessName = json['businessName']?.toString() ?? json['name']?.toString();
    if (businessId.isEmpty) {
      throw Exception('Business ID is required but was not provided in the response');
    }
    if (businessName == null || businessName.trim().isEmpty) {
      throw Exception('Business name is required but was not provided in the response');
    }
    
    return Business(
      id: businessId,
      name: businessName.trim(),
      businessRegNumber: json['businessRegNumber']?.toString(),
      ceoId: ceoId,
    );
  }
}

class Branch {
  final String id;
  final String name;
  final String? location;
  final String businessId;
  final String? managerId;
  final String? managerName;

  Branch({
    required this.id,
    required this.name,
    this.location,
    required this.businessId,
    this.managerId,
    this.managerName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['branchId'] ?? json['id'] ?? '',
      name: json['branchName'] ?? json['name'] ?? '',
      location: json['location'],
      businessId: json['businessId'] ?? '',
      managerId: json['managerId'],
      managerName: json['managerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'managerId': managerId,
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? location,
    String? businessId,
    String? managerId,
    String? managerName,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      businessId: businessId ?? this.businessId,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
    );
  }
}




