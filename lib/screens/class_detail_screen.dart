import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import '../models/assignment.dart';
import '../services/firestore_service.dart';
import 'attendance_screen.dart';
import 'assignment_detail_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final String className;

  const ClassDetailScreen({super.key, required this.className});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _makePhoneCall(String phoneNumber) async {
     final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
     if (await canLaunchUrl(launchUri)) {
       await launchUrl(launchUri);
     }
  }

  void _showBroadcastAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Assignment to Broadcast'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Assignment>>(
            stream: _firestoreService.getAssignments(className: widget.className),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final assignments = snapshot.data ?? [];
              if (assignments.isEmpty) return const Text('No assignments found for this class.');

              return ListView.builder(
                shrinkWrap: true,
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return ListTile(
                    title: Text(assignment.title),
                    subtitle: Text('Due: ${assignment.dueDate.toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to the existing Targeted Sharing screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssignmentDetailScreen(assignment: assignment)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class ${widget.className}'),
      ),
      body: Column(
        children: [
          // Actions Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AttendanceScreen(className: widget.className)),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Attendance'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBroadcastAssignmentDialog,
                    icon: const Icon(Icons.send),
                    label: const Text('Broadcast'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: const Text('Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // Students List
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _firestoreService.getStudents(widget.className),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final students = snapshot.data!;
                if (students.isEmpty) {
                  return const Center(child: Text('No students in this class.'));
                }

                return ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(student.name[0].toUpperCase())),
                      title: Text(student.name),
                      subtitle: Text(student.phoneNumber.isNotEmpty ? student.phoneNumber : 'No phone'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (student.phoneNumber.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.blue),
                              onPressed: () => _makePhoneCall(student.phoneNumber),
                              tooltip: 'Call',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteStudent(student),
                            tooltip: 'Delete Student',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firestoreService.deleteStudent(student.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student ${student.name} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting student: $e')),
          );
        }
      }
    }
  }
}
