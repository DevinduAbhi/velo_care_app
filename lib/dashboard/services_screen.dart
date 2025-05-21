import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _noteController.dispose();
    _serviceDateController.dispose();
    _otherServiceController.dispose();
    super.dispose();
  }

  // KEEPING ALL ORIGINAL FIREBASE METHODS EXACTLY THE SAME
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
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
          SnackBar(
            content: const Text('Service note saved successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        _clearForm();
        _tabController.animateTo(1);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
        SnackBar(
          content: const Text('Service note deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ORIGINAL FIREBASE QUERY - UNCHANGED
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

  // MODERN UI COMPONENTS
  Widget _buildServiceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['serviceType'] ?? 'Unknown Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outlined,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => _deleteService(doc.id),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildServiceDetail(
                icon: Icons.calendar_today,
                text: data['serviceDate'] ?? 'No date',
              ),
              const SizedBox(height: 8),
              _buildServiceDetail(
                icon: Icons.attach_money,
                text: '${data['cost']?.toString() ?? '0'} LKR',
              ),
              const SizedBox(height: 8),
              _buildServiceDetail(
                icon: Icons.speed,
                text: '${data['mileage']?.toString() ?? '0'} km',
              ),
              if (data['note'] != null && data['note'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                const SizedBox(height: 12),
                Text(
                  data['note'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDetail({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
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
                Icon(Icons.error_outline,
                    size: 50, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Database Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        if (docs.isNotEmpty &&
            !docs.first.data().toString().contains('createdAt')) {
          docs = _sortDocs(docs);
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No service notes yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildServiceCard(docs[index]),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildAddServiceForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Service Type', context),
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
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Theme.of(context).cardTheme.color,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedServiceType == 'Other')
              TextFormField(
                controller: _otherServiceController,
                decoration: _inputDecoration('Specify Service Type', context),
                validator: (value) =>
                    _selectedServiceType == 'Other' && value!.isEmpty
                        ? 'Enter service type'
                        : null,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Cost (LKR)', context),
              validator: (value) {
                if (value!.isEmpty) return 'Enter cost';
                if (int.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Mileage (km)', context),
              validator: (value) {
                if (value!.isEmpty) return 'Enter mileage';
                if (int.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: _inputDecoration('Service Date', context),
              validator: (value) => value!.isEmpty ? 'Select date' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration('Note (optional)', context),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SAVE SERVICE NOTE',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Notes'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline)),
            Tab(icon: Icon(Icons.list_alt)),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddServiceForm(),
          _buildServiceList(),
        ],
      ),
    );
  }
}
