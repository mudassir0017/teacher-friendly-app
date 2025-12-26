class Teacher {
  final String id;
  final String name;
  final String email;
  final String address;
  final String? imageUrl;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'imageUrl': imageUrl,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map, {String? id}) {
    return Teacher(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}
