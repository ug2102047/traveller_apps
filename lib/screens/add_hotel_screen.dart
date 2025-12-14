import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddHotelScreen extends StatefulWidget {
  final String? placeName;
  const AddHotelScreen({this.placeName, super.key});

  @override
  State<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.placeName != null) {
      _placeController.text = widget.placeName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedImage = picked;
            _pickedImageBytes = bytes;
          });
        } else {
          setState(() => _pickedImage = picked);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    final storageRef = FirebaseStorage.instance.ref().child(
      'hotels/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    try {
      TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = _pickedImageBytes ?? await file.readAsBytes();
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        snapshot = await uploadTask.whenComplete(() {});
      } else {
        final uploadTask = storageRef.putFile(File(file.path));
        snapshot = await uploadTask.whenComplete(() {});
      }
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);
    String? imageUrl;
    try {
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
      }

      String normalize(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final placeText = _placeController.text.trim();
      final placeKey = normalize(placeText);

      await FirebaseFirestore.instance.collection('hotels').add({
        'name': _nameController.text.trim(),
        'short_description': _shortDescController.text.trim(),
        'description': _descController.text.trim(),
        'price_range': _priceController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'place': placeText,
        'place_key': placeKey,
        'image': imageUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hotel added successfully')));
      Navigator.of(context).pop(true);
    } catch (e, st) {
      // Print full error & stack to console for debugging
      print('AddHotelScreen: Failed to add hotel: $e');
      print(st);

      // Show a more detailed error dialog so the user can see what went wrong
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to add hotel'),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add hotel: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Debug helper: attempt a minimal Firestore write to check permissions
  Future<void> _testFirestoreWrite() async {
    try {
      await FirebaseFirestore.instance.collection('hotels_test').add({
        'test': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test write succeeded'),
          content: const Text(
            'Firestore write test succeeded. Permissions look OK.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      print('Test write failed: $e');
      print(st);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test write failed'),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Hotel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Hotel Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter hotel name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Full Description',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price Range'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Info'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: 'Place / Landmark',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter place name' : null,
              ),
              const SizedBox(height: 12),
              _pickedImage != null
                  ? Column(
                      children: [
                        if (kIsWeb && _pickedImageBytes != null)
                          Image.memory(
                            _pickedImageBytes!,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        else
                          Image.file(
                            File(_pickedImage!.path),
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _pickedImage = null;
                            _pickedImageBytes = null;
                          }),
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove'),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick Photo'),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Hotel'),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                OutlinedButton(
                  onPressed: _testFirestoreWrite,
                  child: const Text('DEBUG: Test Firestore Write'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
