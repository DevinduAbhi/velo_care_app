import 'package:flutter/material.dart';

class CarTipsPage extends StatefulWidget {
  const CarTipsPage({super.key});

  @override
  State<CarTipsPage> createState() => _CarTipsPageState();
}

class _CarTipsPageState extends State<CarTipsPage> {
  String _searchQuery = '';
  int _selectedCategory = 0;
  final List<int> _favoriteIndicators = [];

  final List<IndicatorItem> _allIndicators = [
    // Critical (Red) Indicators
    IndicatorItem(
      imagePath: 'assets/temp.png',
      name: 'Engine Temp',
      description: 'Engine overheating warning',
      severity: Severity.critical,
      issue: 'Coolant leak, faulty thermostat',
      solution: '1. Pull over immediately\n2. Check coolant level',
      immediateAction: 'STOP DRIVING',
      videoUrl: 'https://youtu.be/3o-cHdz1uk8?si=fcxIZLOIcX6qm5IL',
    ),
    IndicatorItem(
      imagePath: 'assets/oil.png',
      name: 'Oil Pressure',
      description: 'Low oil pressure detected',
      severity: Severity.critical,
      issue: 'Oil leak, clogged filter',
      solution: '1. Stop driving\n2. Check oil level',
      immediateAction: 'Engine damage likely',
      videoUrl: 'https://example.com/oil_pressure',
    ),
    IndicatorItem(
      imagePath: 'assets/brake.png',
      name: 'Brake System',
      description: 'Brake system malfunction',
      severity: Severity.critical,
      issue: 'Low brake fluid, worn pads',
      solution: '1. Test brakes carefully\n2. Check fluid',
      immediateAction: 'Brake failure possible',
      videoUrl: 'https://example.com/brake_warning',
    ),
    IndicatorItem(
      imagePath: 'assets/battery.png',
      name: 'Charging',
      description: 'Battery not charging',
      severity: Severity.critical,
      issue: 'Alternator failure',
      solution: '1. Turn off electronics\n2. Check terminals',
      immediateAction: 'Limited driving time',
      videoUrl: 'https://example.com/charging_system',
    ),

    // Warning (Yellow/Orange) Indicators
    IndicatorItem(
      imagePath: 'assets/engine.png',
      name: 'Check Engine',
      description: 'Engine issue detected',
      severity: Severity.warning,
      issue: 'Multiple possible causes',
      solution: '1. Check gas cap\n2. Get diagnostic',
      immediateAction: 'Service soon',
      videoUrl: 'https://example.com/check_engine',
    ),
    IndicatorItem(
      imagePath: 'assets/abs.png',
      name: 'ABS Warning',
      description: 'ABS system fault',
      severity: Severity.warning,
      issue: 'Sensor or module problem',
      solution: '1. Brakes still work\n2. Get scanned',
      immediateAction: 'No anti-lock protection',
      videoUrl: 'https://example.com/abs_warning',
    ),
    IndicatorItem(
      imagePath: 'assets/tire-pressure.png',
      name: 'Tire Pressure',
      description: 'Low tire pressure',
      severity: Severity.warning,
      issue: 'Underinflation or puncture',
      solution: '1. Check all tires\n2. Inflate properly',
      immediateAction: 'Reduced safety',
      videoUrl: 'https://example.com/tire_pressure',
    ),
    IndicatorItem(
      imagePath: 'assets/traction-control.png',
      name: 'Traction Control',
      description: 'System disabled',
      severity: Severity.warning,
      issue: 'Button pressed or sensor issue',
      solution: '1. Check if turned off\n2. Restart vehicle',
      immediateAction: 'Less stability',
      videoUrl: 'https://example.com/traction_control',
    ),

    // Informational (Blue/Green) Indicators
    IndicatorItem(
      imagePath: 'assets/high-beam.png',
      name: 'High Beams',
      description: 'High beams active',
      severity: Severity.info,
      issue: 'Normal operation',
      solution: 'Toggle stalk to switch',
      immediateAction: 'Dim for traffic',
      videoUrl: 'https://example.com/high_beams',
    ),
    IndicatorItem(
      imagePath: 'assets/cruise.png',
      name: 'Cruise Control',
      description: 'Speed control active',
      severity: Severity.info,
      issue: 'Normal operation',
      solution: 'Press SET/RES buttons',
      immediateAction: 'No obstacle detection',
      videoUrl: 'https://example.com/cruise_control',
    ),
    IndicatorItem(
      imagePath: 'assets/fog-light.png',
      name: 'Fog Lights',
      description: 'Fog lights on',
      severity: Severity.info,
      issue: 'Normal operation',
      solution: 'Controlled by switch',
      immediateAction: 'Use in low visibility',
      videoUrl: 'https://example.com/fog_lights',
    ),
    IndicatorItem(
      imagePath: 'assets/maintenance.png',
      name: 'Maintenance',
      description: 'Service reminder',
      severity: Severity.info,
      issue: 'Scheduled service',
      solution: 'Complete maintenance',
      immediateAction: 'Schedule service',
      videoUrl: 'https://example.com/maintenance_light',
    ),
  ];

  List<IndicatorItem> get _filteredIndicators {
    List<IndicatorItem> filtered = _allIndicators;

    if (_selectedCategory == 1) {
      filtered =
          filtered.where((i) => i.severity == Severity.critical).toList();
    } else if (_selectedCategory == 2) {
      filtered = filtered.where((i) => i.severity == Severity.warning).toList();
    } else if (_selectedCategory == 3) {
      filtered = filtered.where((i) => i.severity == Severity.info).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((indicator) {
        return indicator.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Care Tips'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tips...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(height: 16),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(0, 'All', theme),
                      _buildCategoryChip(1, 'Critical', theme, Colors.red),
                      _buildCategoryChip(2, 'Warning', theme, Colors.orange),
                      _buildCategoryChip(3, 'Info', theme, Colors.blue),
                      _buildCategoryChip(4, 'Favorites', theme, Colors.pink),
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
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching tips found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _filteredIndicators.length,
                    itemBuilder: (context, index) {
                      final indicator = _filteredIndicators[index];
                      final originalIndex = _allIndicators.indexOf(indicator);
                      return _TipBox(
                        indicator: indicator,
                        isFavorite: _favoriteIndicators.contains(originalIndex),
                        onFavoriteToggle: () => _toggleFavorite(originalIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int index, String label, ThemeData theme,
      [Color? color]) {
    final isSelected = _selectedCategory == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = index),
        backgroundColor: theme.cardColor,
        selectedColor: color?.withOpacity(0.2),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: isSelected
              ? color ?? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                isSelected ? color ?? Colors.transparent : theme.dividerColor,
          ),
        ),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final IndicatorItem indicator;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _TipBox({
    required this.indicator,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        _showDetailsDialog(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: indicator.severity.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        indicator.imagePath,
                        width: 24,
                        height: 24,
                        color: indicator.severity.color,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.warning,
                            color: indicator.severity.color,
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    indicator.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    indicator.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.pink : theme.disabledColor,
                  size: 20,
                ),
                onPressed: onFavoriteToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(indicator.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: indicator.severity.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        indicator.imagePath,
                        width: 16,
                        height: 16,
                        color: indicator.severity.color,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.warning,
                            color: indicator.severity.color,
                            size: 16,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    indicator.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Possible Issue',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(indicator.issue),
              const SizedBox(height: 16),
              Text(
                'Immediate Action',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(indicator.immediateAction),
              const SizedBox(height: 16),
              Text(
                'Solution',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(indicator.solution),
              if (indicator.videoUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Watch Video Guide'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening: ${indicator.videoUrl}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
  final String imagePath;
  final String name;
  final String description;
  final Severity severity;
  final String issue;
  final String solution;
  final String immediateAction;
  final String videoUrl;

  IndicatorItem({
    required this.imagePath,
    required this.name,
    required this.description,
    required this.severity,
    required this.issue,
    required this.solution,
    required this.immediateAction,
    this.videoUrl = '',
  });
}
