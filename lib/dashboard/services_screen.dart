import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _serviceDateController = TextEditingController();
  final TextEditingController _otherServiceController = TextEditingController();

  String? _selectedServiceType;
  final List<String> _serviceTypes = [
    'Oil Change',
    'Tire Change',
    'Brake Service',
    'Battery Replacement',
    'AC Service',
    'Other'
  ];

  @override
  void dispose() {
    _costController.dispose();
    _mileageController.dispose();
    _noteController.dispose();
    _serviceDateController.dispose();
    _otherServiceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _serviceDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _addService() async {
    if (_formKey.currentState!.validate()) {
      try {
        final serviceType = _selectedServiceType == 'Other'
            ? _otherServiceController.text
            : _selectedServiceType;

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        await FirebaseFirestore.instance.collection('services').add({
          'serviceType': serviceType,
          'cost': int.parse(_costController.text),
          'mileage': int.parse(_mileageController.text),
          'note': _noteController.text,
          'serviceDate': _serviceDateController.text,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _clearForm();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _costController.clear();
    _mileageController.clear();
    _noteController.clear();
    _serviceDateController.clear();
    _otherServiceController.clear();
    setState(() => _selectedServiceType = null);
  }

  Future<void> _deleteService(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(docId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service note deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot> _getServicesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('services')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__')
        .snapshots()
        .handleError((error) {
      if (error.toString().contains('index')) {
        return FirebaseFirestore.instance
            .collection('services')
            .where('userId', isEqualTo: user.uid)
            .snapshots();
      }
      throw error;
    });
  }

  List<QueryDocumentSnapshot> _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final aDate = a['createdAt'] as Timestamp?;
      final bDate = b['createdAt'] as Timestamp?;
      return (bDate ?? Timestamp.now()).compareTo(aDate ?? Timestamp.now());
    });
    return docs;
  }

  Widget _buildServiceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['serviceType'] ?? 'Unknown Service',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteService(doc.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(data['serviceDate'] ?? 'No date'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${data['cost']?.toString() ?? '0'} LKR'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.speed, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${data['mileage']?.toString() ?? '0'} km'),
              ],
            ),
            if (data['note'] != null && data['note'].isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(data['note']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Database Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(snapshot.error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        if (docs.isNotEmpty &&
            !docs.first.data().toString().contains('createdAt')) {
          docs = _sortDocs(docs);
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No service notes yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildServiceCard(docs[index]),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Notes'),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Service Type'),
                      value: _selectedServiceType,
                      items: _serviceTypes
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedServiceType = value),
                      validator: (value) =>
                          value == null ? 'Select service type' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedServiceType == 'Other')
                      TextFormField(
                        controller: _otherServiceController,
                        decoration: _inputDecoration('Specify Service Type'),
                        validator: (value) =>
                            _selectedServiceType == 'Other' && value!.isEmpty
                                ? 'Enter service type'
                                : null,
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Cost (LKR)'),
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter cost';
                        if (int.tryParse(value) == null)
                          return 'Enter valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Mileage (km)'),
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter mileage';
                        if (int.tryParse(value) == null)
                          return 'Enter valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: _inputDecoration('Service Date'),
                      validator: (value) =>
                          value!.isEmpty ? 'Select date' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDecoration('Note (optional)'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'SAVE SERVICE NOTE',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // List Section
          Expanded(
            child: _buildServiceList(),
          ),
        ],
      ),
    );
  }
}
