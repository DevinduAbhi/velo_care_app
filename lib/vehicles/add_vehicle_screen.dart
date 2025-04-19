import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddVehicleScreen({super.key, this.initialData});

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _numberController = TextEditingController();
  final _chassisController = TextEditingController();
  final _mileageController = TextEditingController();
  final _fuelTypeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'Other'
  ];

  String? _imageUrl;
  File? _selectedImageFile;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isEditing = false;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialData != null;

    if (_isEditing) {
      _docId = widget.initialData!['docId'];
      _makeController.text = widget.initialData!['make'] ?? '';
      _modelController.text = widget.initialData!['model'] ?? '';
      _yearController.text = widget.initialData!['year']?.toString() ?? '';
      _numberController.text = widget.initialData!['number'] ?? '';
      _chassisController.text = widget.initialData!['chassis'] ?? '';
      _mileageController.text =
          widget.initialData!['mileage']?.toString() ?? '';
      _fuelTypeController.text =
          _fuelTypes.contains(widget.initialData!['fuelType'])
              ? widget.initialData!['fuelType']
              : 'Petrol';
      _imageUrl = widget.initialData!['image'];
    } else {
      _fuelTypeController.text = 'Petrol';
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _numberController.dispose();
    _chassisController.dispose();
    _mileageController.dispose();
    _fuelTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      setState(() => _isUploading = true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'vehicles/${user.uid}/$timestamp.jpg';

      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to save a vehicle')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      String? finalImageUrl = _imageUrl;

      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImage(_selectedImageFile!);
        if (uploadedUrl == null) {
          setState(() => _isSubmitting = false);
          return;
        }
        finalImageUrl = uploadedUrl;
      }

      final vehicleData = <String, dynamic>{
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(), // Stored as String
        'number': _numberController.text.trim(),
        'chassis': _chassisController.text.trim(),
        'mileage': _mileageController.text.trim(), // Stored as String
        'fuelType': _fuelTypeController.text.trim(),
        'image': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      if (_isEditing && _docId != null) {
        await _firestore.collection('vehicles').doc(_docId).update(vehicleData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated successfully')),
        );
      } else {
        vehicleData['createdAt'] = FieldValue.serverTimestamp();
        DocumentReference docRef =
            await _firestore.collection('vehicles').add(vehicleData);
        final String newDocId = docRef.id;
        vehicleData['docId'] = newDocId;
        await docRef.update({'docId': newDocId});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully')),
        );
      }

      if (mounted) Navigator.pop(context, vehicleData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving vehicle: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildImagePickerSection(),
                  const SizedBox(height: 20),
                  _buildVehicleDetailsSection(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
          if (_isUploading || _isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _buildImageContent(),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Choose Photo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
      );
    } else if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 10),
        Text(
          'Add Vehicle Photo',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _makeController,
              label: 'Make (Brand)',
              icon: Icons.branding_watermark,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _modelController,
              label: 'Model',
              icon: Icons.directions_car,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _yearController,
              label: 'Year',
              icon: Icons.calendar_today,
              inputType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Enter valid year';
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _numberController,
              label: 'License Plate',
              icon: Icons.confirmation_number,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _chassisController,
              label: 'Chassis Number',
              icon: Icons.drive_file_rename_outline,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _mileageController,
              label: 'Current Mileage (km)',
              icon: Icons.speed,
              inputType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Enter valid mileage';
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildFuelTypeDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _fuelTypeController.text,
      decoration: InputDecoration(
        labelText: 'Fuel Type',
        prefixIcon: Icon(Icons.local_gas_station, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      items: _fuelTypes.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() => _fuelTypeController.text = newValue!);
      },
      validator: (value) => value!.isEmpty ? 'Please select fuel type' : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isUploading || _isSubmitting) ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isEditing ? 'UPDATE VEHICLE' : 'SAVE VEHICLE',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: validator,
    );
  }
}
