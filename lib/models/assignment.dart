import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final String className;
  final String subject;
  final DateTime dueDate;
  final String? fileUrl; // URL from Storage if you implement file upload later
  final String teacherId;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.className,
    required this.subject,
    required this.dueDate,
    this.fileUrl,
    required this.teacherId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'className': className,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'fileUrl': fileUrl,
      'teacherId': teacherId,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, {String? id}) {
    return Assignment(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      fileUrl: map['fileUrl'],
      teacherId: map['teacherId'] ?? '',
    );
  }
}
