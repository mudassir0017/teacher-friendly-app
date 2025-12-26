import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedClass = '';
  List<String> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }
  
  Future<void> _loadClasses() async {
    final classes = await _firestoreService.getClasses();
    if(mounted) {
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty && _selectedClass.isEmpty) {
          _selectedClass = _classes.first;
        }
      });
    }
  }

  void _addNewStudent() {
    final nameController = TextEditingController();
    final classController = TextEditingController(text: _selectedClass);
    final subjectController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student Name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: classController,
                decoration: const InputDecoration(
                  labelText: 'Class (e.g., 9A) *',
                  hintText: 'Required to group students',
                ),
              ),
              const SizedBox(height: 8),
               TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject (Optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (with Country Code)',
                  hintText: 'e.g. +1234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && classController.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final newStudent = Student(
                  id: '', 
                  name: nameController.text.trim(),
                  className: classController.text.trim(),
                  subject: subjectController.text.trim(),
                  email: emailController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  teacherId: user.uid,
                );

                await _firestoreService.addStudent(newStudent);
                
                if (!_classes.contains(classController.text.trim())) {
                  _loadClasses();
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Class: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedClass.isNotEmpty && _classes.contains(_selectedClass) ? _selectedClass : null,
                    hint: const Text('Select Class'),
                    items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClass = val ?? '';
                      });
                    },
                  ),
                ),
                 IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadClasses,
                  tooltip: 'Refresh Classes',
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _selectedClass.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 64,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Please select or add a class',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<Student>>(
                stream: _firestoreService.getStudents(_selectedClass),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final students = snapshot.data!;
                  if (students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No students found in this class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to add students',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                student.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${student.className}${student.phoneNumber.isNotEmpty ? ' • ${student.phoneNumber}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmDeleteStudent(student),
                          ),
                          onTap: () {
                             // Could show details dialog here
                          },
                        ),
                      );
                    },
                  );
                },
              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}