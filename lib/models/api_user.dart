class ApiUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String company;
  final String city;

  const ApiUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.company,
    required this.city,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final address = json['address'] is Map
        ? json['address'] as Map<String, dynamic>
        : <String, dynamic>{};
    final companyData = json['company'] is Map
        ? json['company'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ApiUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'No name',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      company: companyData['name']?.toString() ?? 'No company',
      city: address['city']?.toString() ?? 'No city',
    );
  }
}
