import 'package:flutter/material.dart';
import 'vehicles/add_vehicle_screen.dart';
import 'login_screen.dart';
import 'settings/profile.dart';
import 'settings/contact_us.dart';
import 'settings/help_support.dart';
import 'themes/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About Us',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Velo Care is a car maintenance app that helps users manage their vehicle maintenance schedule.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Version: 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.themeNotifier.themeMode ==
        ThemeMode.dark; // Changed from .value to .themeMode
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Profile Section
            _buildSettingsCard(
              context,
              icon: Icons.account_circle_rounded,
              title: 'Profile',
              subtitle: 'Edit your profile details',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              ),
            ),

            // Add Vehicle Section
            _buildSettingsCard(
              context,
              icon: Icons.directions_car_rounded,
              title: 'Add Vehicle',
              subtitle: 'Add a new vehicle to your profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddVehicleScreen()),
              ),
            ),

            // About Us Section
            _buildSettingsCard(
              context,
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              subtitle: 'Learn more about the app',
              onTap: () => _showAboutUsDialog(context),
            ),

            // Help Section
            _buildSettingsCard(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get help with the app',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpSupportPage()),
              ),
            ),

            // Contact Us Section
            _buildSettingsCard(
              context,
              icon: Icons.contact_mail_rounded,
              title: 'Contact Us',
              subtitle: 'Reach out to support team',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactUsPage()),
              ),
            ),

            // Dark Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.brightness_6_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Dark Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Toggle between dark and light mode',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Switch.adaptive(
                  value: isDarkMode,
                  onChanged: (value) => widget.themeNotifier.toggleTheme(value),
                  thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                    (states) => isDarkMode
                        ? const Icon(Icons.dark_mode_rounded)
                        : const Icon(Icons.light_mode_rounded),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Log Out Section
            Container(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
                ),
                title: Text(
                  'Log Out',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.error.withOpacity(0.6),
                ),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(themeNotifier: widget.themeNotifier),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
