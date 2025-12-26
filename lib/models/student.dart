class Student {
  final String id;
  final String name;
  final String className;
  final String subject;
  final String email;
  final String phoneNumber;
  final String teacherId;
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.subject,
    this.email = '',
    this.phoneNumber = '',
    required this.teacherId,
    this.isPresent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'className': className,
      'subject': subject,
      'email': email,
      'phoneNumber': phoneNumber,
      'teacherId': teacherId,
      'isPresent': isPresent,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, {String? id}) {
    return Student(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      teacherId: map['teacherId'] ?? '',
      isPresent: map['isPresent'] ?? false,
    );
  }
}
