class UserModel {
  String? id;
  String? name;
  String? email;
  String? role;

  UserModel({this.id, this.name, this.email, this.role});

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}
