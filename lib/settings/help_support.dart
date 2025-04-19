import 'package:flutter/material.dart';
import 'contact_us.dart'; // Make sure this path is correct

class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help & Support"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Middle Image
            Center(
              child: Image.asset(
                'assets/help_support.png', // Replace with your actual image path
                height: 300,
              ),
            ),
            //SizedBox(height: 30),

            // FAQ Section
            _buildFAQTile(
              question: "How do I add a vehicle?",
              answer:
                  "Go to Settings > Add Vehicle and fill in the required details.",
            ),
            _buildFAQTile(
              question: "How do I set reminders?",
              answer:
                  "Open the Reminders section from the dashboard and create a new one.",
            ),
            _buildFAQTile(
              question: "Can I backup my data?",
              answer:
                  "Yes, your data is securely stored in the cloud using Firebase.",
            ),
            _buildFAQTile(
              question: "How can I reset my password?",
              answer:
                  "Use the 'Forgot Password' option on the login screen to reset your password.",
            ),

            SizedBox(height: 30),

            // Contact Support Button
            ElevatedButton.icon(
              icon: Icon(Icons.contact_support),
              label: Text("Contact Support"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.question_answer, color: Colors.blue),
        title: Text(question),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
