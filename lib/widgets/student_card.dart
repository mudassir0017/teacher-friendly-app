import 'package:flutter/material.dart';
import '../models/student.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final ValueChanged<bool?> onAttendanceChanged;

  const StudentCard({
    super.key,
    required this.student,
    required this.onAttendanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CheckboxListTile(
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('ID: ${student.id}'),
        value: student.isPresent,
        activeColor: Colors.green,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: student.isPresent
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: student.isPresent ? Colors.green : Colors.grey,
          ),
        ),
        onChanged: onAttendanceChanged,
      ),
    );
  }
}
