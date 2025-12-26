import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/assignment.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSending = false;

  Future<void> _sendToStudent(Student student) async {
    if (student.phoneNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number saved for ${student.name}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    String attachment = widget.assignment.fileUrl != null 
        ? "\n\n📎 *Attachment:* ${widget.assignment.fileUrl}" 
        : "";

    String text = "👋 Hello ${student.name},\n\n"
        "📚 *New Assignment: ${widget.assignment.title}*\n"
        "🏫 Class: ${widget.assignment.className}\n"
        "📖 Subject: ${widget.assignment.subject}\n\n"
        "📝 *Description:*\n${widget.assignment.description}\n\n"
        "📅 *Due Date:* ${widget.assignment.dueDate.toString().split(' ')[0]}$attachment\n\n"
        "Please submit your work on time. Good luck! 🌟";

    // Remove any non-digit characters from phone number for the URL
    String phone = student.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Fallback if number doesn't exist or is invalid
    if (phone.isEmpty) { 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
    }

    String url = "https://wa.me/$phone?text=${Uri.encodeComponent(text)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening WhatsApp for ${student.name}...'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _sendToAllStudents(List<Student> students) async {
    setState(() => _isSending = true);
    
    final studentsWithPhone = students.where((s) => s.phoneNumber.isNotEmpty).toList();
    
    if (studentsWithPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students have phone numbers saved'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      setState(() => _isSending = false);
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send to All Students?'),
        content: Text(
          'This will open WhatsApp ${studentsWithPhone.length} times to send the assignment to all students with phone numbers.\n\nYou will need to manually send each message.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Send to All'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isSending = false);
      return;
    }

    // Send to each student with a delay
    for (int i = 0; i < studentsWithPhone.length; i++) {
      await _sendToStudent(studentsWithPhone[i]);
      // Add delay between messages to avoid overwhelming
      if (i < studentsWithPhone.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    setState(() => _isSending = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent to ${studentsWithPhone.length} students!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.assignment.className),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment Details Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.assignment.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.assignment.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            widget.assignment.dueDate.toString().split(' ')[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.assignment.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.assignment.fileUrl != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'File attached',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Send to Students',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<Student>>(
                  stream: _firestoreService.getStudents(widget.assignment.className),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final students = snapshot.data!;
                    final withPhone = students.where((s) => s.phoneNumber.isNotEmpty).length;
                    
                    return ElevatedButton.icon(
                      onPressed: _isSending ? null : () => _sendToAllStudents(students),
                      icon: _isSending 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(_isSending ? 'Sending...' : 'Send to All ($withPhone)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _firestoreService.getStudents(widget.assignment.className),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data ?? [];

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
                          'No students in this class',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final hasPhone = student.phoneNumber.isNotEmpty;
                    
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasPhone 
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
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
                          child: Row(
                            children: [
                              Icon(
                                hasPhone ? Icons.phone : Icons.phone_disabled,
                                size: 14,
                                color: hasPhone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasPhone ? student.phoneNumber : 'No phone number',
                                style: TextStyle(
                                  color: hasPhone ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: hasPhone
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send, color: Color(0xFF10B981)),
                                  onPressed: () => _sendToStudent(student),
                                  tooltip: 'Send via WhatsApp',
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No phone',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
}
