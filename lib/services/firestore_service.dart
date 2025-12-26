import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';
import '../models/assignment.dart';
import '../models/attendance.dart';
import '../models/teacher.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _persistenceEnabled = false;

  FirestoreService._internal() {
    _enablePersistenceOnce();
  }

  void _enablePersistenceOnce() {
    if (_persistenceEnabled) return;
    try {
      // Note: Settings must be applied before any other interaction with Firestore
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _persistenceEnabled = true;
      debugPrint('✅ Firestore Persistence Enabled in Service');
    } catch (e) {
      debugPrint('ℹ️ Firestore Settings already configured: $e');
    }
  }

  String? get currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ Warning: FirestoreService.currentUserId is NULL. Auth state might be transitioning.');
    }
    return uid;
  }

  // --- Teacher Profile ---

  // Get teacher profile
  Stream<Teacher?> getTeacherProfile() {
    if (currentUserId == null) return Stream.value(null);
    return _db.collection('teachers').doc(currentUserId).snapshots().map((doc) {
      if (doc.exists) {
        return Teacher.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    });
  }

  // Update teacher profile
  Future<void> updateTeacherProfile(Teacher teacher) async {
    if (currentUserId == null) return;
    try {
      await _db.collection('teachers').doc(currentUserId).set({
        ...teacher.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Teacher profile updated');
    } catch (e) {
      debugPrint('❌ Error updating teacher profile: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(Uint8List bytes, String fileName) async {
    if (currentUserId == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profiles')
          .child(currentUserId!)
          .child(fileName);
      
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  // --- Students ---

  // Add a new student
  Future<void> addStudent(Student student) async {
    if (currentUserId == null) return;
    try {
      await _db.collection('students').add({
        ...student.toMap(),
        'teacherId': currentUserId, // Ensure linked to teacher
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Ensure the class exists in our dedicated classes collection
      await addClass(student.className);
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    }
  }

  // Get students for a specific class (and optionally subject)
  Stream<List<Student>> getStudents(String className) {
    if (currentUserId == null) return Stream.value([]);
    
    return _db
        .collection('students')
        .where('teacherId', isEqualTo: currentUserId)
        .where('className', isEqualTo: className)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Student.fromMap(doc.data(), id: doc.id);
      }).toList();
    });
  }

  // Get students for a specific class once (not a stream)
  Future<List<Student>> getStudentsOnce(String className) async {
    if (currentUserId == null) return [];
    
    final snapshot = await _db
        .collection('students')
        .where('teacherId', isEqualTo: currentUserId)
        .where('className', isEqualTo: className)
        .get();
        
    return snapshot.docs.map((doc) {
      return Student.fromMap(doc.data(), id: doc.id);
    }).toList();
  }
  
  // Get all classes for the teacher (from dedicated collection)
  Future<List<String>> getClasses() async {
    if (currentUserId == null) return [];
    try {
      final snapshot = await _db.collection('classes')
          .where('teacherId', isEqualTo: currentUserId)
          .get();
          
      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ No classes found in explicit collection, checking students for migration...');
        // Fallback: If no classes collection exists yet, try to derive from students
        final studentSnapshot = await _db.collection('students')
            .where('teacherId', isEqualTo: currentUserId)
            .get();
        
        final studentClasses = studentSnapshot.docs.map((doc) => doc['className'] as String).toSet().toList();
        
        if (studentClasses.isNotEmpty) {
           debugPrint('ℹ️ Migrating ${studentClasses.length} classes for user $currentUserId');
           final batch = _db.batch();
           for (var className in studentClasses) {
              final docId = '${currentUserId}_$className';
              batch.set(_db.collection('classes').doc(docId), {
                'name': className,
                'teacherId': currentUserId,
                'createdAt': FieldValue.serverTimestamp(),
              });
           }
           await batch.commit();
        }
        
        studentClasses.sort();
        return studentClasses;
      }

      final classes = snapshot.docs.map((doc) => doc['name'] as String).toList();
      classes.sort();
      return classes;
    } catch (e) {
      debugPrint('Error getting classes: $e');
      return [];
    }
  }

  // Add a new class name explicitly
  Future<void> addClass(String className) async {
    if (currentUserId == null) return;
    try {
      final docId = '${currentUserId}_$className';
      await _db.collection('classes').doc(docId).set({
        'name': className,
        'teacherId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Class "$className" registered successfully in Firestore');
    } catch (e) {
      debugPrint('❌ Error adding class "$className": $e');
    }
  }

  // Stream of class names for real-time UI updates
  Stream<List<String>> getClassesStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _db.collection('classes')
        .where('teacherId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final classes = snapshot.docs.map((doc) => doc['name'] as String).toList();
          classes.sort();
          return classes;
        });
  }

  // --- Assignments ---

  // Add a new assignment
  Future<void> addAssignment(Assignment assignment) async {
    if (currentUserId == null) return;
    try {
      await _db.collection('assignments').add({
        ...assignment.toMap(),
        'teacherId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Ensure class exists
      await addClass(assignment.className);
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      rethrow;
    }
  }

  // Get assignments
  Stream<List<Assignment>> getAssignments({String? className}) {
    if (currentUserId == null) return Stream.value([]);

    Query query = _db.collection('assignments')
        .where('teacherId', isEqualTo: currentUserId)
        .orderBy('dueDate', descending: false);

    if (className != null && className.isNotEmpty) {
      query = query.where('className', isEqualTo: className);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Assignment.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();
    });
  }

  // Upload file (Cross-platform support)
  Future<String?> uploadFile({File? file, Uint8List? bytes, required String fileName}) async {
    if (currentUserId == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('assignments')
          .child(currentUserId!)
          .child(fileName);
      
      if (kIsWeb && bytes != null) {
        await ref.putData(bytes);
      } else if (file != null) {
        await ref.putFile(file);
      } else if (bytes != null) {
        await ref.putData(bytes);
      } else {
        throw Exception('No file or bytes provided for upload');
      }

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // --- Attendance ---

  // Save attendance record
  Future<void> saveAttendance(AttendanceRecord attendance) async {
    debugPrint('📝 saveAttendance called');
    debugPrint('📝 Current User ID: $currentUserId');
    
    if (currentUserId == null) {
      debugPrint('❌ No current user ID!');
      throw Exception('User not logged in');
    }
    
    try {
      // Create a unique ID based on date and class
      final dateStr = '${attendance.date.year}-${attendance.date.month.toString().padLeft(2, '0')}-${attendance.date.day.toString().padLeft(2, '0')}';
      final docId = '${currentUserId}_${attendance.className}_$dateStr';

      debugPrint('📝 Document ID: $docId');
      debugPrint('📝 Date string: $dateStr');
      debugPrint('📝 Preparing to save to Firestore...');

      final data = {
        ...attendance.toMap(),
        'teacherId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 Data to save: $data');
      debugPrint('📝 Writing to Firestore...');

      await _db.collection('attendance').doc(docId).set(data);
      
      // Ensure class exists
      await addClass(attendance.className);

      debugPrint('✅ Firestore write completed successfully!');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in saveAttendance: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get attendance records for a class
  Stream<List<AttendanceRecord>> getAttendanceRecords(String className, {int? limitDays}) {
    if (currentUserId == null) return Stream.value([]);

    Query query = _db.collection('attendance')
        .where('teacherId', isEqualTo: currentUserId)
        .where('className', isEqualTo: className)
        .orderBy('date', descending: true);

    if (limitDays != null) {
      query = query.limit(limitDays);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();
    });
  }

  // Get attendance for a specific date
  Future<AttendanceRecord?> getAttendanceForDate(String className, DateTime date) async {
    if (currentUserId == null) return null;

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docId = '${currentUserId}_${className}_$dateStr';

    try {
      final doc = await _db.collection('attendance').doc(docId).get();
      if (doc.exists) {
        return AttendanceRecord.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return null;
    }
  }

  // Get attendance statistics for dashboard (Stream version for real-time)
  Stream<Map<String, dynamic>> getAttendanceStatsStream() {
    if (currentUserId == null) return Stream.value({});

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _db.collection('attendance')
        .where('teacherId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .snapshots()
        .map((snapshot) {
          int totalRecords = snapshot.docs.length;
          double avgAttendance = 0.0;

          if (totalRecords > 0) {
            double sum = 0.0;
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final present = data['presentCount'] ?? 0;
              final total = data['totalCount'] ?? 1;
              sum += (present / total) * 100;
            }
            avgAttendance = sum / totalRecords;
          }

          return {
            'totalRecords': totalRecords,
            'averageAttendance': avgAttendance,
          };
        });
  }

  // Get total student count
  Stream<int> getStudentCountStream() {
    if (currentUserId == null) return Stream.value(0);
    return _db.collection('students')
        .where('teacherId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all recent attendance records for the teacher
  Stream<List<AttendanceRecord>> getAllRecentAttendance({int limit = 5}) {
    if (currentUserId == null) return Stream.value([]);

    return _db.collection('attendance')
        .where('teacherId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data(), id: doc.id);
      }).toList();
    });
  }

  // --- Delete Operations ---

  // Delete a student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _db.collection('students').doc(studentId).delete();
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  // Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _db.collection('assignments').doc(assignmentId).delete();
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      rethrow;
    }
  }

  // Delete an entire class (all students in that class)
  Future<void> deleteClass(String className) async {
    if (currentUserId == null) return;
    try {
      final snapshot = await _db.collection('students')
          .where('teacherId', isEqualTo: currentUserId)
          .where('className', isEqualTo: className)
          .get();
      
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Also delete the class itself from the classes collection
      final classDocId = '${currentUserId}_$className';
      batch.delete(_db.collection('classes').doc(classDocId));

      // Also delete assignments for this class? 
      // Probably safer to just delete students for now, or ask. 
      // But usually "delete class" in this app means clearing the student roster.
      final assignmentSnapshot = await _db.collection('assignments')
          .where('teacherId', isEqualTo: currentUserId)
          .where('className', isEqualTo: className)
          .get();
          
      for (var doc in assignmentSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Also delete attendance records?
      final attendanceSnapshot = await _db.collection('attendance')
          .where('teacherId', isEqualTo: currentUserId)
          .where('className', isEqualTo: className)
          .get();

      for (var doc in attendanceSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }
}
