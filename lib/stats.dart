import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to check bold text setting
  bool _isBoldText(BuildContext context) {
    return MediaQuery.of(context).boldText ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station)),
            Tab(icon: Icon(Icons.build)),
            Tab(icon: Icon(Icons.eco)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFuelTab(),
          _buildServicesTab(),
          _buildTipsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToAddFuel(context),
              child: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Widget _buildFuelTab() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthlyFuelSummary(),
            const SizedBox(height: 24),
            _buildFuelConsumptionChart(),
            const SizedBox(height: 24),
            _buildRecentFuelEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyFuelSummary() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('fuel_entries')
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThan: Timestamp.fromDate(firstDayOfMonth))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();

        double totalLiters = 0;
        double totalCost = 0;
        double totalDistance = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalLiters += (data['liters'] as num).toDouble();
          totalCost += (data['cost'] as num).toDouble();
          totalDistance += (data['odometer'] as num).toDouble();
        }

        final avgCostPerLiter = totalLiters > 0 ? totalCost / totalLiters : 0;
        final efficiency = totalLiters > 0 ? totalDistance / totalLiters : 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Fuel Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildMetricTile(
                  icon: Icons.water_drop,
                  label: 'Fuel Used',
                  value: '${totalLiters.toStringAsFixed(1)} L',
                ),
                _buildMetricTile(
                  icon: Icons.attach_money,
                  label: 'Total Cost',
                  value:
                      '${NumberFormat.currency(symbol: 'LKR ').format(totalCost)}',
                ),
                _buildMetricTile(
                  icon: Icons.speed,
                  label: 'Avg Efficiency',
                  value: '${efficiency.toStringAsFixed(1)} km/L',
                ),
                _buildMetricTile(
                  icon: Icons.money,
                  label: 'Cost/Liter',
                  value:
                      '${NumberFormat.currency(symbol: 'LKR ').format(avgCostPerLiter)}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelConsumptionChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('fuel_entries')
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();

        final entries = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'date': (data['date'] as Timestamp).toDate(),
            'liters': data['liters'],
          };
        }).toList();

        return SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: entries.map((entry) {
                return BarChartGroupData(
                  x: entries.indexOf(entry),
                  barRods: [
                    BarChartRodData(
                      toY: (entry['liters'] as num).toDouble(),
                      color: Theme.of(context).primaryColor,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM dd')
                              .format(entries[value.toInt()]['date']),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: _isBoldText(context)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: _isBoldText(context)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentFuelEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Fuel Entries',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('fuel_entries')
              .where('userId', isEqualTo: _userId)
              .orderBy('date', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoading();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: Text(
                    '${data['liters']} L - ${NumberFormat.currency(symbol: 'LKR ').format(data['cost'])}',
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(
                          (data['date'] as Timestamp).toDate(),
                        ),
                  ),
                  trailing: Text(
                    '${data['odometer']} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServicesTab() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildServiceCostSummary(),
            const SizedBox(height: 24),
            _buildRecentServices(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCostSummary() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('services')
          .where('userId', isEqualTo: _userId)
          .where('serviceDate',
              isGreaterThan: DateFormat('yyyy-MM-dd').format(firstDayOfMonth))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();

        double totalCost = 0;
        final serviceCounts = <String, int>{};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalCost += (data['cost'] as num).toDouble();
          final serviceType = data['serviceType'] as String;
          serviceCounts[serviceType] = (serviceCounts[serviceType] ?? 0) + 1;
        }

        final mostCommonService = serviceCounts.isNotEmpty
            ? serviceCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : 'None';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Service Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildMetricTile(
                  icon: Icons.attach_money,
                  label: 'Total Cost',
                  value:
                      '${NumberFormat.currency(symbol: 'LKR ').format(totalCost)}',
                ),
                _buildMetricTile(
                  icon: Icons.build,
                  label: 'Services Done',
                  value: '${snapshot.data!.docs.length}',
                ),
                _buildMetricTile(
                  icon: Icons.star,
                  label: 'Most Common',
                  value: mostCommonService,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Services',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('services')
              .where('userId', isEqualTo: _userId)
              .orderBy('serviceDate', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoading();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.build),
                  title: Text(data['serviceType'] ?? 'Unknown Service'),
                  subtitle: Text(
                    DateFormat.yMMMd().format(
                      DateFormat('yyyy-MM-dd').parse(data['serviceDate']),
                    ),
                  ),
                  trailing: Text(
                    '${NumberFormat.currency(symbol: 'LKR ').format(data['cost'])}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTipsTab() {
    final tips = [
      {
        'title': 'Proper Tire Pressure',
        'description':
            'Maintain recommended pressure (check monthly) for 3% better mileage',
        'icon': Icons.tire_repair,
      },
      {
        'title': 'Smooth Acceleration',
        'description':
            'Avoid rapid starts - gentle acceleration saves 10-15% fuel',
        'icon': Icons.speed,
      },
      {
        'title': 'Reduce Idling',
        'description': 'Turn off engine if stopped for more than 30 seconds',
        'icon': Icons.timer_off,
      },
      {
        'title': 'Regular Maintenance',
        'description':
            'Clean air filters and proper oil changes improve efficiency',
        'icon': Icons.build,
      },
      {
        'title': 'Reduce Weight',
        'description': 'Every 50kg reduces efficiency by 1-2%',
        'icon': Icons.fitness_center,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tips[index]['icon'] as IconData,
                    size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tips[index]['title'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tips[index]['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddFuel(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFuelScreen()),
    );
    setState(() {});
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }
}

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isFullTank = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    _litersController.dispose();
    _costController.dispose();
    _odometerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance.collection('fuel_entries').add({
          'liters': double.parse(_litersController.text),
          'cost': double.parse(_costController.text),
          'odometer': int.parse(_odometerController.text),
          'date': Timestamp.fromDate(
              DateFormat('yyyy-MM-dd').parse(_dateController.text)),
          'userId': user.uid,
          'isFullTank': _isFullTank,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Fuel Entry'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _litersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Liters Added',
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter liters';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Cost (LKR)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter cost';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Odometer (km)',
                    prefixIcon: Icon(Icons.speed),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter odometer';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Select date';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Full Tank Fill'),
                  value: _isFullTank,
                  onChanged: (value) => setState(() => _isFullTank = value),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SAVE FUEL ENTRY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
