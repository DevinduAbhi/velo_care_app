import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InsuranceTrackerScreen extends StatefulWidget {
  const InsuranceTrackerScreen({Key? key}) : super(key: key);

  @override
  State<InsuranceTrackerScreen> createState() => _InsuranceTrackerScreenState();
}

class _InsuranceTrackerScreenState extends State<InsuranceTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _providerController = TextEditingController();
  final _policyNumberController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _durationMonths = 12;

  Future<void> _addInsurancePolicy() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final expiryDate = DateTime(
        _startDate.year,
        _startDate.month + _durationMonths,
        _startDate.day,
      );

      await FirebaseFirestore.instance.collection('insurance_policies').add({
        'userId': user.uid,
        'providerName': _providerController.text,
        'policyNumber': _policyNumberController.text,
        'startDate': Timestamp.fromDate(_startDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'durationMonths': _durationMonths,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _providerController.clear();
      _policyNumberController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Policy saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Policy Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _providerController,
                        decoration:
                            const InputDecoration(labelText: 'Provider'),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _policyNumberController,
                        decoration:
                            const InputDecoration(labelText: 'Policy Number'),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                            'Start Date: ${DateFormat.yMd().format(_startDate)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _durationMonths,
                        items: [6, 12, 24]
                            .map((months) => DropdownMenuItem(
                                  value: months,
                                  child: Text('$months months'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _durationMonths = value ?? 12),
                        decoration:
                            const InputDecoration(labelText: 'Duration'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addInsurancePolicy,
                        child: const Text('Save Policy'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Policy List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('insurance_policies')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('expiryDate')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final policies = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    itemCount: policies.length,
                    itemBuilder: (context, index) {
                      final data =
                          policies[index].data() as Map<String, dynamic>;
                      final expiryDate =
                          (data['expiryDate'] as Timestamp).toDate();
                      final daysLeft =
                          expiryDate.difference(DateTime.now()).inDays;

                      return Card(
                        child: ListTile(
                          title: Text(data['providerName']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Policy #: ${data['policyNumber']}'),
                              Text(
                                  'Expires: ${DateFormat.yMd().format(expiryDate)}'),
                              Text(
                                daysLeft <= 0
                                    ? 'EXPIRED'
                                    : '$daysLeft days remaining',
                                style: TextStyle(
                                  color:
                                      daysLeft <= 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePolicy(policies[index].id),
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
      ),
    );
  }

  Future<void> _deletePolicy(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('insurance_policies')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Policy deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    _policyNumberController.dispose();
    super.dispose();
  }
}
