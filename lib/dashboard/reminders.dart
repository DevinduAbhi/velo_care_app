import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _editingReminderId;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getRemindersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? reminder]) async {
    if (reminder != null) {
      _titleController.text = reminder['title'];
      _descController.text = reminder['description'] ?? '';
      _selectedDay = (reminder['date'] as Timestamp).toDate();
      _editingReminderId = reminder['id'];
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedDay = DateTime.now();
      _editingReminderId = null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(_editingReminderId == null ? 'Add Reminder' : 'Edit Reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        _selectedDay == null
                            ? 'Select Date'
                            : DateFormat.yMMMd().format(_selectedDay!),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectTime(context),
                      child: Text(_formatTime(_selectedTime)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _selectedDay != null) {
                _saveReminder();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDay == null) return;

    try {
      final reminderData = {
        'title': _titleController.text,
        'description': _descController.text,
        'date': Timestamp.fromDate(_selectedDay!),
        'time': _formatTime(_selectedTime),
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingReminderId != null) {
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(_editingReminderId)
            .update(reminderData);
      } else {
        reminderData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('reminders')
            .add(reminderData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reminder: $e')),
      );
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await FirebaseFirestore.instance.collection('reminders').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddEditDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(Duration(days: 365)),
              lastDay: DateTime.now().add(Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getRemindersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final reminders = snapshot.data!;
                final filteredReminders = _selectedDay == null
                    ? reminders
                    : reminders.where((r) {
                        final date = (r['date'] as Timestamp).toDate();
                        return isSameDay(date, _selectedDay!);
                      }).toList();

                if (filteredReminders.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedDay == null
                          ? 'No reminders'
                          : 'No reminders for ${DateFormat.yMMMd().format(_selectedDay!)}',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredReminders.length,
                  itemBuilder: (context, index) {
                    final reminder = filteredReminders[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(reminder['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reminder['description'] != null)
                              Text(reminder['description']),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                    (reminder['date'] as Timestamp).toDate(),
                                  ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(reminder),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteReminder(reminder['id']),
                            ),
                          ],
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
