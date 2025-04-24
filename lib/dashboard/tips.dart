// tips.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CarTipsPage extends StatefulWidget {
  const CarTipsPage({super.key});

  @override
  State<CarTipsPage> createState() => _CarTipsPageState();
}

class _CarTipsPageState extends State<CarTipsPage> {
  bool _isDarkMode = false;
  String _searchQuery = '';
  int _selectedCategory = 0; // 0=All, 1=Critical, 2=Warning, 3=Info
  final List<int> _favoriteIndicators = [];

  final List<IndicatorItem> _allIndicators = [
    // Critical (Red) Indicators
    IndicatorItem(
      icon: 'assets/icons/temperature.svg',
      name: 'Engine Temperature',
      description: 'Engine overheating warning',
      severity: Severity.critical,
      issue:
          'Coolant leak, faulty thermostat, broken water pump, or cooling fan failure',
      solution: '1. Pull over immediately and turn off engine\n'
          '2. Wait 30 minutes before checking coolant level\n'
          '3. If low, refill with 50/50 coolant-water mix\n'
          '4. Never open radiator when hot\n'
          '5. If light stays on, call for tow service',
      immediateAction: 'STOP DRIVING - Continuing can cause engine seizure',
      videoUrl: 'https://example.com/engine_overheating',
    ),
    IndicatorItem(
      icon: 'assets/icons/oil.svg',
      name: 'Oil Pressure',
      description: 'Low oil pressure detected',
      severity: Severity.critical,
      issue: 'Oil leak, clogged filter, pump failure, or low oil level',
      solution: '1. Stop driving immediately\n'
          '2. Check oil level with dipstick\n'
          '3. Top up if low with recommended oil\n'
          '4. If level is normal, suspect pump or sensor issue\n'
          '5. Do not restart engine if light stays on',
      immediateAction: 'Engine damage likely if driven with low oil pressure',
      videoUrl: 'https://example.com/oil_pressure',
    ),
    IndicatorItem(
      icon: 'assets/icons/brake.svg',
      name: 'Brake System',
      description: 'Brake system malfunction',
      severity: Severity.critical,
      issue: 'Low brake fluid, worn pads, hydraulic failure, or ABS problem',
      solution: '1. Test brakes at low speed in safe area\n'
          '2. Check brake fluid level in reservoir\n'
          '3. Top up with DOT-approved fluid if low\n'
          '4. If pedal feels spongy, have system bled\n'
          '5. Avoid sudden stops - braking distance may increase',
      immediateAction: 'Brake failure possible - proceed with extreme caution',
      videoUrl: 'https://example.com/brake_warning',
    ),
    IndicatorItem(
      icon: 'assets/icons/battery.svg',
      name: 'Charging System',
      description: 'Battery not charging',
      severity: Severity.critical,
      issue: 'Alternator failure, bad battery, loose belts, or wiring issues',
      solution: '1. Turn off non-essential electronics\n'
          '2. Check battery terminals for corrosion\n'
          '3. Try jump-starting if battery is dead\n'
          '4. Drive directly to repair shop\n'
          '5. Vehicle may stall when battery drains completely',
      immediateAction: 'Limited driving time remaining - typically 10-20 miles',
      videoUrl: 'https://example.com/charging_system',
    ),

    // Warning (Yellow/Orange) Indicators
    IndicatorItem(
      icon: 'assets/icons/engine.svg',
      name: 'Check Engine',
      description: 'Engine management issue',
      severity: Severity.warning,
      issue: '100+ possible causes from loose gas cap to serious misfires',
      solution: '1. First check if gas cap is loose (common fix)\n'
          '2. If light is flashing, reduce load and get immediate service\n'
          '3. For solid light, have codes read at auto parts store\n'
          '4. Note any symptoms (rough idle, loss of power)\n'
          '5. Schedule diagnostic service',
      immediateAction:
          'Flashing light = stop driving. Solid light = service soon',
      videoUrl: 'https://example.com/check_engine',
    ),
    IndicatorItem(
      icon: 'assets/icons/abs.svg',
      name: 'ABS Warning',
      description: 'Anti-lock brake system fault',
      severity: Severity.warning,
      issue:
          'Wheel speed sensor failure, low battery voltage, or module problem',
      solution: '1. Conventional brakes still work normally\n'
          '2. Avoid panic stops that would trigger ABS\n'
          '3. Have system scanned for specific fault codes\n'
          '4. Common causes include dirty wheel sensors\n'
          '5. Repair before winter driving conditions',
      immediateAction: 'Brakes work but without anti-lock protection',
      videoUrl: 'https://example.com/abs_warning',
    ),
    IndicatorItem(
      icon: 'assets/icons/tire.svg',
      name: 'Tire Pressure',
      description: 'Low tire pressure detected',
      severity: Severity.warning,
      issue: 'Underinflation, puncture, temperature change, or sensor fault',
      solution: '1. Check all tires with quality gauge\n'
          '2. Inflate to PSI listed on driver door jamb sticker\n'
          '3. Inspect for nails/slow leaks\n'
          '4. Reset system after inflation (check manual)\n'
          '5. If light returns, may need sensor battery replacement',
      immediateAction: 'Improper inflation reduces safety and fuel economy',
      videoUrl: 'https://example.com/tire_pressure',
    ),
    IndicatorItem(
      icon: 'assets/icons/traction.svg',
      name: 'Traction Control',
      description: 'Stability system disabled',
      severity: Severity.warning,
      issue: 'System malfunction, button pressed, or wheel sensor issue',
      solution: '1. Check if system was accidentally turned off\n'
          '2. Try restarting vehicle\n'
          '3. If light stays on, avoid slippery conditions\n'
          '4. Have system scanned for codes\n'
          '5. Common causes include faulty yaw rate sensor',
      immediateAction: 'Vehicle less stable in emergency maneuvers',
      videoUrl: 'https://example.com/traction_control',
    ),

    // Informational (Blue/Green) Indicators
    IndicatorItem(
      icon: 'assets/icons/highbeam.svg',
      name: 'High Beams',
      description: 'High beam headlights active',
      severity: Severity.info,
      issue: 'Normal operation when high beams engaged',
      solution:
          'Toggle stalk forward/backward to switch between high/low beams\n'
          'Automatic systems may require dashboard control adjustment',
      immediateAction: 'Remember to dim for oncoming traffic',
      videoUrl: 'https://example.com/high_beams',
    ),
    IndicatorItem(
      icon: 'assets/icons/cruise.svg',
      name: 'Cruise Control',
      description: 'Speed control system active',
      severity: Severity.info,
      issue: 'Normal operation or possible brake switch fault',
      solution: '1. Set/Resume: Press SET or RES buttons\n'
          '2. Cancel: Tap brake or cancel button\n'
          '3. If system won\'t engage, check brake lights\n'
          '4. Adaptive systems may require radar calibration',
      immediateAction: 'System maintains speed but doesn\'t detect obstacles',
      videoUrl: 'https://example.com/cruise_control',
    ),
    IndicatorItem(
      icon: 'assets/icons/foglight.svg',
      name: 'Fog Lights',
      description: 'Fog lights activated',
      severity: Severity.info,
      issue: 'Normal operation when fog lights turned on',
      solution:
          'Usually controlled by separate switch or headlight dial rotation\n'
          'Check owner\'s manual for specific activation method',
      immediateAction: 'Use only in low visibility conditions',
      videoUrl: 'https://example.com/fog_lights',
    ),
    IndicatorItem(
      icon: 'assets/icons/maintenance.svg',
      name: 'Maintenance Required',
      description: 'Scheduled service reminder',
      severity: Severity.info,
      issue: 'Mileage-based service interval reached',
      solution: '1. Reset light after completing maintenance\n'
          '2. Typical services: oil change, tire rotation\n'
          '3. Check maintenance schedule in manual\n'
          '4. Some systems track multiple service intervals',
      immediateAction: 'Schedule service at your earliest convenience',
      videoUrl: 'https://example.com/maintenance_light',
    ),
  ];

  List<IndicatorItem> get _filteredIndicators {
    List<IndicatorItem> filtered = _allIndicators;

    // Apply category filter
    if (_selectedCategory == 1) {
      filtered =
          filtered.where((i) => i.severity == Severity.critical).toList();
    } else if (_selectedCategory == 2) {
      filtered = filtered.where((i) => i.severity == Severity.warning).toList();
    } else if (_selectedCategory == 3) {
      filtered = filtered.where((i) => i.severity == Severity.info).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((indicator) {
        return indicator.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            indicator.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            indicator.issue.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply favorites filter if in favorites mode
    if (_selectedCategory == 4) {
      filtered = filtered
          .where((i) => _favoriteIndicators.contains(_allIndicators.indexOf(i)))
          .toList();
    }

    return filtered;
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favoriteIndicators.contains(index)) {
        _favoriteIndicators.remove(index);
      } else {
        _favoriteIndicators.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode
          ? ThemeData.dark().copyWith(
              cardColor: Colors.grey[900],
              dividerColor: Colors.grey[800],
              chipTheme: ChipThemeData(
                backgroundColor: Colors.grey[800],
                selectedColor: Colors.red.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            )
          : ThemeData.light().copyWith(
              cardColor: Colors.white,
              dividerColor: Colors.grey[200],
              chipTheme: const ChipThemeData(
                backgroundColor: Color(0xFFEEEEEE),
                selectedColor: Color(0xFFFFCDD2),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Car Care Tips'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: 'Toggle dark mode',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tips...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(0, 'All'),
                        _buildCategoryChip(1, 'Critical', Colors.red),
                        _buildCategoryChip(2, 'Warning', Colors.orange),
                        _buildCategoryChip(3, 'Info', Colors.blue),
                        _buildCategoryChip(4, 'Favorites', Colors.pink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredIndicators.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: _isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching tips found',
                            style: TextStyle(
                              fontSize: 18,
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          if (_selectedCategory == 4)
                            TextButton(
                              child: const Text('Browse all tips'),
                              onPressed: () =>
                                  setState(() => _selectedCategory = 0),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredIndicators.length,
                      itemBuilder: (context, index) {
                        final indicator = _filteredIndicators[index];
                        final originalIndex = _allIndicators.indexOf(indicator);
                        return _TipCard(
                          indicator: indicator,
                          isDarkMode: _isDarkMode,
                          isFavorite:
                              _favoriteIndicators.contains(originalIndex),
                          onFavoriteToggle: () =>
                              _toggleFavorite(originalIndex),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index, String label, [Color? color]) {
    final isSelected = _selectedCategory == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = index),
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? color ?? (_isDarkMode ? Colors.white : Colors.black)
              : _isDarkMode
                  ? Colors.grey[300]
                  : Colors.grey[700],
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color:
                isSelected ? color ?? Colors.transparent : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IndicatorItem indicator;
  final bool isDarkMode;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _TipCard({
    required this.indicator,
    required this.isDarkMode,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: indicator.severity.color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              indicator.icon,
              width: 24,
              height: 24,
              color: indicator.severity.color,
            ),
          ),
        ),
        title: Text(
          indicator.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          indicator.description,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? Colors.pink
                : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
          ),
          onPressed: onFavoriteToggle,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Possible Issue', indicator.issue),
                const SizedBox(height: 16),
                _buildInfoSection(
                    'Immediate Action', indicator.immediateAction),
                const SizedBox(height: 16),
                _buildInfoSection('Solution', indicator.solution),
                if (indicator.severity == Severity.critical) ...[
                  const SizedBox(height: 16),
                  _buildCriticalWarning(),
                ],
                if (indicator.videoUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildVideoButton(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content.replaceAll('\n', '\n• '),
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Critical Warning: Requires immediate attention to prevent vehicle damage or unsafe driving conditions',
              style: TextStyle(
                color: Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Watch Video Guide'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () {
        // TODO: Implement video playback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening video: ${indicator.videoUrl}'),
          ),
        );
      },
    );
  }
}

enum Severity {
  critical,
  warning,
  info;

  Color get color {
    switch (this) {
      case Severity.critical:
        return Colors.red;
      case Severity.warning:
        return Colors.orange;
      case Severity.info:
        return Colors.blue;
    }
  }
}

class IndicatorItem {
  final String icon;
  final String name;
  final String description;
  final Severity severity;
  final String issue;
  final String solution;
  final String immediateAction;
  final String videoUrl;

  IndicatorItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.severity,
    required this.issue,
    required this.solution,
    required this.immediateAction,
    this.videoUrl = '',
  });
}
