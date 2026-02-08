class User {
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String? businessId;
  final String? branchId;
  final String? branchName;

  User({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.businessId,
    this.branchId,
    this.branchName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? json['managerId'] ?? json['clerkId'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? json['firstname'] ?? '',
      lastName: json['lastName'] ?? json['lastname'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role'] ?? ''),
      businessId: json['businessId'],
      branchId: json['branchId'],
      branchName: json['branchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.name,
      'businessId': businessId,
      'branchId': branchId,
      'branchName': branchName,
    };
  }
}

enum UserRole {
  ceo,
  manager,
  clerk;

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'CEO':
        return UserRole.ceo;
      case 'MANAGER':
        return UserRole.manager;
      case 'CLERK':
        return UserRole.clerk;
      default:
        return UserRole.clerk;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.ceo:
        return 'CEO';
      case UserRole.manager:
        return 'Manager';
      case UserRole.clerk:
        return 'Clerk';
    }
  }
}




