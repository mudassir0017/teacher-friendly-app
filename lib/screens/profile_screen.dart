import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/teacher.dart';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Teacher? _currentTeacher;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    // Note: getTeacherProfile is a Stream, but for initial load 
    // we can either listen or just wait for the first value.
    // For simplicity, we'll listen to the stream.
  }

  void _updateControllers(Teacher? teacher) {
    if (teacher != null && _nameController.text.isEmpty) {
      _nameController.text = teacher.name;
      _addressController.text = teacher.address;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedImageName = result.files.single.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Profile validation failed');
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('🔵 Starting profile save process...');

    try {
      String? imageUrl = _currentTeacher?.imageUrl;

      if (_selectedImageBytes != null && _selectedImageName != null) {
        debugPrint('🔵 Attempting to upload profile image: $_selectedImageName');
        final uploadedUrl = await _firestoreService.uploadProfileImage(
          _selectedImageBytes!,
          _selectedImageName!,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          debugPrint('✅ Image uploaded successfully: $imageUrl');
        } else {
          debugPrint('⚠️ Image upload returned null');
        }
      }

      final uid = _firestoreService.currentUserId;
      debugPrint('🔵 Target UID: $uid');
      
      if (uid == null) {
        throw Exception('User UID is null. Cannot save profile.');
      }

      final updatedTeacher = Teacher(
        id: uid,
        name: _nameController.text.trim(),
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        address: _addressController.text.trim(),
        imageUrl: imageUrl,
      );

      debugPrint('🔵 Sending update to Firestore for collection "teachers" doc "$uid"');
      await _firestoreService.updateTeacherProfile(updatedTeacher);
      debugPrint('✅ Firestore write operation completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
      }
    } catch (e) {
      debugPrint('❌ CRITICAL ERROR saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: StreamBuilder<Teacher?>(
        stream: _firestoreService.getTeacherProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _nameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          _currentTeacher = snapshot.data;
          _updateControllers(_currentTeacher);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _selectedImageBytes != null
                                ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                : (_currentTeacher?.imageUrl != null
                                    ? Image.network(_currentTeacher!.imageUrl!, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person, size: 64, color: Colors.grey),
                                      )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Details Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: FirebaseAuth.instance.currentUser?.email,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
