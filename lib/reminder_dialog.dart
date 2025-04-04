import 'package:flutter/material.dart';

class ReminderDialog extends StatelessWidget {
  final Map<String, dynamic>? initialData;

  ReminderDialog({this.initialData});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: initialData?["title"] ?? "");
    final TextEditingController dueInController =
        TextEditingController(text: initialData?["dueIn"] ?? "");

    return AlertDialog(
      title: Text(initialData == null ? "Add Reminder" : "Edit Reminder"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: "Reminder Title"),
          ),
          TextField(
            controller: dueInController,
            decoration: InputDecoration(labelText: "Due in (e.g., 500 km)"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final updatedReminder = {
              "title": titleController.text,
              "dueIn": dueInController.text,
            };
            Navigator.of(context).pop(updatedReminder);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
