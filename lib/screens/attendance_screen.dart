import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/firestore_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;

  const AttendanceScreen({super.key, required this.className});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Local state to track attendance changes before saving
  // Map<StudentId, isPresent>
  final Map<String, bool> _attendanceMap = {};
  bool _isSaving = false;
  bool _isLoadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingAttendance();
  }

  Future<void> _loadExistingAttendance() async {
    try {
      final existingRecord = await _firestoreService.getAttendanceForDate(
        widget.className,
        DateTime.now(),
      );
      
      if (existingRecord != null && mounted) {
        setState(() {
          _attendanceMap.addAll(existingRecord.studentAttendance);
        });
      }
    } catch (e) {
      debugPrint('Error loading existing attendance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }
  
  Future<void> _saveAttendance(List<Student> students) async {
    int presentCount = 0;
    
    for (var student in students) {
      if (_attendanceMap[student.id] ?? false) {
        presentCount++;
      }
    }
    
    int totalCount = students.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Attendance'),
        content: Text(
          'Marking $presentCount / $totalCount present for ${widget.className}.\n\nThis will save the attendance record for today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Save Attendance'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      debugPrint('🔵 Starting attendance save...');
      debugPrint('🔵 Class: ${widget.className}');
      debugPrint('🔵 Present: $presentCount / $totalCount');
      debugPrint('🔵 Teacher ID: ${_firestoreService.currentUserId}');
      
      // Create attendance record
      final attendanceRecord = AttendanceRecord(
        id: '',
        className: widget.className,
        date: DateTime.now(),
        studentAttendance: Map.from(_attendanceMap),
        presentCount: presentCount,
        totalCount: totalCount,
        teacherId: _firestoreService.currentUserId ?? '',
      );

      debugPrint('🔵 Attendance record created');
      debugPrint('🔵 Calling saveAttendance...');

      // Save to Firestore
      await _firestoreService.saveAttendance(attendanceRecord);

      debugPrint('✅ Attendance saved successfully!');

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Attendance saved! $presentCount/$totalCount present'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Go back to dashboard
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving attendance: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Error saving attendance',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(e.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Student>>(
      stream: _firestoreService.getStudents(widget.className),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        
        if (!snapshot.hasData || _isLoadingExisting) {
          return Scaffold(
            appBar: AppBar(title: Text('Attendance - ${widget.className}')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final students = snapshot.data!;
        
        if (students.isEmpty) {
           return Scaffold(
             appBar: AppBar(title: Text('Attendance - ${widget.className}')),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.group_off, size: 60, color: Colors.grey),
                   const SizedBox(height: 10),
                   Text('No students found in ${widget.className}.'),
                   const SizedBox(height: 5),
                   const Text('Go to "Students" screen to add them.', style: TextStyle(color: Colors.grey)),
                 ],
               ),
             ),
           );
        }

        // Initialize missing students in map (putIfAbsent is safe here)
        for (var s in students) {
          _attendanceMap.putIfAbsent(s.id, () => false);
        }

        // Count current attendance
        int presentCount = 0;
        for (var s in students) {
          if (_attendanceMap[s.id] ?? false) {
            presentCount++;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text('Attendance - ${widget.className}'),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Summary Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Status',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$presentCount / ${students.length} Present',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${((presentCount / students.length) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                for (var s in students) {
                                  _attendanceMap[s.id] = true;
                                }
                              });
                            },
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Mark All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                for (var s in students) {
                                  _attendanceMap[s.id] = false;
                                }
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Clear All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _attendanceMap[student.id] ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPresent ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          student.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPresent ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${student.id}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        value: isPresent,
                        activeColor: const Color(0xFF10B981),
                        checkColor: Colors.white,
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPresent 
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: isPresent ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _attendanceMap[student.id] = val ?? false;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _isSaving 
              ? null 
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _saveAttendance(students),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Submit Attendance',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
