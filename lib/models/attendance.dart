import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String className;
  final DateTime date;
  final Map<String, bool> studentAttendance; // studentId -> isPresent
  final int presentCount;
  final int totalCount;
  final String teacherId;

  AttendanceRecord({
    required this.id,
    required this.className,
    required this.date,
    required this.studentAttendance,
    required this.presentCount,
    required this.totalCount,
    required this.teacherId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'date': Timestamp.fromDate(date),
      'studentAttendance': studentAttendance,
      'presentCount': presentCount,
      'totalCount': totalCount,
      'teacherId': teacherId,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return AttendanceRecord(
      id: id ?? map['id'] ?? '',
      className: map['className'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      studentAttendance: Map<String, bool>.from(map['studentAttendance'] ?? {}),
      presentCount: map['presentCount'] ?? 0,
      totalCount: map['totalCount'] ?? 0,
      teacherId: map['teacherId'] ?? '',
    );
  }

  double get attendancePercentage {
    if (totalCount == 0) return 0.0;
    return (presentCount / totalCount) * 100;
  }
}
