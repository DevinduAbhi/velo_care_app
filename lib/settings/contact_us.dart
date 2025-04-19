import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/contact_us.png',
                  width: 350,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // const SizedBox(height: 30),

            const Text(
              'We’d love to hear from you!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            const Text(
              'Whether you have a question about reminders, logs, or just want to give feedback, feel free to reach out.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Phone
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Phone'),
              subtitle: const Text('+94 779 314 727'),
            ),

            // Email
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              subtitle: const Text('support@velocare.app'),
            ),

            // Support hours
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text('Support Hours'),
              subtitle: const Text('Mon – Fri, 9 AM – 6 PM'),
            ),
          ],
        ),
      ),
    );
  }
}
