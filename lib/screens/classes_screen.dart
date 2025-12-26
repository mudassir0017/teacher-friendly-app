import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'class_detail_screen.dart';
import 'students_screen.dart'; // For adding new students (which creates classes)

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  Future<void> _confirmDeleteClass(String className) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete class "$className"? This will delete all students, assignments, and attendance records associated with this class.'),
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
        await _firestoreService.deleteClass(className);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Class "$className" deleted successfully')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting class: $e')),
          );
        }
      }
    }
  }

  void _showAddClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Class Name',
            hintText: 'e.g., 10th Grade, Math 101',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _firestoreService.addClass(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add New Class',
            onPressed: _showAddClassDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Student',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const StudentsScreen())
              ).then((_) => setState(() {}));
            },
          )
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _firestoreService.getClassesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
             return FutureBuilder<List<String>>(
                future: _firestoreService.getClasses(), // The future version has migration logic
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                  final migrantClasses = futureSnapshot.data ?? [];
                  if (migrantClasses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No classes found.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showAddClassDialog,
                            child: const Text('Create Your First Class'),
                          )
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final className = classes[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailScreen(className: className),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, size: 32, color: Colors.blue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            className,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                           const Text('Tap to Manage', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDeleteClass(className),
                      ),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
