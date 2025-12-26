import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/assignment.dart';
import '../services/firestore_service.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _shareOnWhatsApp(Assignment assignment) async {
    // 1. Fetch students for this class
    final students = await _firestoreService.getStudentsOnce(assignment.className);
    final studentsWithPhone = students.where((s) => s.phoneNumber.isNotEmpty).toList();

    if (!mounted) return;

    if (studentsWithPhone.isNotEmpty) {
      // If students with phone numbers exist, suggest direct broadcast
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Broadcast on WhatsApp?'),
          content: Text(
            'Found ${studentsWithPhone.length} students with phone numbers in ${assignment.className}.\n\n'
            'Would you like to send this assignment directly to them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('General Share'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Send to Students'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Navigate to detail screen which has the robust "Send to All" logic
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentDetailScreen(assignment: assignment),
          ),
        );
        return;
      }
    }

    // Generic Share (Fallback or User choice)
    String text = "📚 *New Assignment: ${assignment.title}*\n\n"
        "${assignment.description}\n\n"
        "📅 Due Date: ${assignment.dueDate.toString().split(' ')[0]}\n"
        "Subject: ${assignment.subject}\n\n"
        "Please complete this by the due date.";

    // Use https://wa.me/ for better compatibility
    String url = "https://wa.me/?text=${Uri.encodeComponent(text)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final classController = TextEditingController();
    final subjectController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    PlatformFile? selectedPlatformFile;
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              Row(
                children: [
                   Expanded(child: TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class (e.g., 9A)'))),
                   const SizedBox(width: 10),
                   Expanded(child: TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject'))),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Due Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),
              if (selectedPlatformFile != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedPlatformFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        disabledColor: Colors.grey,
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: isCreating ? null : () => setModalState(() => selectedPlatformFile = null),
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: isCreating ? null : () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                      allowMultiple: false,
                      withData: kIsWeb, // Required for Web
                    );
                    if (result != null) {
                      setModalState(() => selectedPlatformFile = result.files.first);
                    }
                  } catch (e) {
                    debugPrint('Error picking file: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error picking file: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(selectedPlatformFile == null ? 'Attach Any File (Word, PDF, etc)' : 'Change Attachment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (titleController.text.isNotEmpty && classController.text.isNotEmpty) {
                    setModalState(() => isCreating = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      String? fileUrl;
                      if (selectedPlatformFile != null) {
                        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${selectedPlatformFile!.name}';
                        
                        fileUrl = await _firestoreService.uploadFile(
                          file: kIsWeb ? null : File(selectedPlatformFile!.path!),
                          bytes: selectedPlatformFile!.bytes,
                          fileName: fileName,
                        );
                      }
                      
                      final newAssignment = Assignment(
                        id: '',
                        title: titleController.text,
                        description: descController.text,
                        className: classController.text,
                        subject: subjectController.text,
                        dueDate: selectedDate,
                        teacherId: user.uid,
                        fileUrl: fileUrl, 
                      );

                      await _firestoreService.addAssignment(newAssignment);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                       if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating assignment: $e')),
                        );
                      }
                    } finally {
                      setModalState(() => isCreating = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isCreating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"?'),
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
        await _firestoreService.deleteAssignment(assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment "${assignment.title}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting assignment: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: StreamBuilder<List<Assignment>>(
        stream: _firestoreService.getAssignments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final assignments = snapshot.data ?? [];
          
          if (assignments.isEmpty) {
            return Center(
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
                    Icons.assignment_outlined,
                    size: 64,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No assignments yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the + button to create one',
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
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentDetailScreen(assignment: assignment),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignment.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          assignment.className,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        assignment.subject,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Due: ${assignment.dueDate.toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (assignment.fileUrl != null) ...[
                                const Spacer(),
                                const Icon(Icons.attach_file, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                const Text(
                                  'Attached',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _confirmDeleteAssignment(assignment),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _shareOnWhatsApp(assignment),
                              icon: const Icon(Icons.share, color: Color(0xFF10B981), size: 18),
                              label: const Text(
                                'Broadcast',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}