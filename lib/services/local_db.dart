import '../models/student.dart';
import '../models/assignment.dart';
import '../models/attendance.dart';

class LocalDatabase {
  // Singleton pattern
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  // Mock in-memory storage
  final List<Student> _students = [];
  final List<Assignment> _assignments = [];
  final List<AttendanceRecord> _attendanceRecords = [];

  // --- Student Operations ---
  Future<void> addStudent(Student student) async {
    _students.add(student);
  }

  Future<List<Student>> getStudents() async {
    return List.from(_students);
  }

  // --- Assignment Operations ---
  Future<void> addAssignment(Assignment assignment) async {
    _assignments.add(assignment);
  }

  Future<List<Assignment>> getAssignments() async {
    return List.from(_assignments);
  }

  // --- Attendance Operations ---
  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    _attendanceRecords.addAll(records);
  }

  Future<List<AttendanceRecord>> getAttendanceForDate(String className, String date) async {
    // Note: In a real app, you'd probably parse the date string or store it more effectively
    return _attendanceRecords
        .where((r) => r.className == className && r.date.toIso8601String().split('T')[0] == date)
        .toList();
  }
}
