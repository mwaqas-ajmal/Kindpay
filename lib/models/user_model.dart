class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  // 🔹 Convert JSON → Object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
    );
  }

  // 🔹 Convert Object → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "email": email,
      "phone": phone,
      "role": role,
      "status": status,
    };
  }
}