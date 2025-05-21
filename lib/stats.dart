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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      setState(() {
        _userId = user?.uid;
        _isLoading = false;
      });
    } catch (e) {
      print("Error getting current user: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isBoldText(BuildContext context) {
    return MediaQuery.of(context).boldText ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fuel Analytics'),
        ),
        body: const Center(
          child: Text('Please sign in to view your fuel stats'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel'),
            Tab(icon: Icon(Icons.eco), text: 'Tips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFuelTab(),
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
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No fuel entries found for this month'),
            ),
          );
        }

        double totalLiters = 0;
        double totalCost = 0;
        double totalDistance = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalLiters += (data['liters'] as num?)?.toDouble() ?? 0;
          totalCost += (data['cost'] as num?)?.toDouble() ?? 0;
          totalDistance += (data['odometer'] as num?)?.toDouble() ?? 0;
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

  Widget _buildFuelConsumptionChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('fuel_entries')
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No fuel entries available to display chart'),
            ),
          );
        }

        final entries = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'date': (data['date'] as Timestamp).toDate(),
            'liters': (data['liters'] as num?)?.toDouble() ?? 0,
          };
        }).toList();

        entries.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        return SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(entries.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entries[index]['liters'] as double,
                      color: Theme.of(context).primaryColor,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= entries.length ||
                          value.toInt() < 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM dd').format(
                              entries[value.toInt()]['date'] as DateTime),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No fuel entries found. Add your first entry!'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final liters = (data['liters'] as num?)?.toDouble() ?? 0;
                final cost = (data['cost'] as num?)?.toDouble() ?? 0;
                final odometer = (data['odometer'] as num?)?.toString() ?? '-';
                final date = data['date'] is Timestamp
                    ? (data['date'] as Timestamp).toDate()
                    : DateTime.now();

                return ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: Text(
                    '${liters.toStringAsFixed(1)} L - ${NumberFormat.currency(symbol: 'LKR ').format(cost)}',
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(date),
                  ),
                  trailing: Text(
                    '$odometer km',
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

  Widget _buildTipsTab() {
    final tips = [
      {
        'title': 'Proper Tire Pressure',
        'description': 'Maintain recommended pressure for better mileage',
        'icon': Icons.tire_repair,
      },
      {
        'title': 'Smooth Acceleration',
        'description': 'Gentle acceleration saves 10-15% fuel',
        'icon': Icons.speed,
      },
      {
        'title': 'Reduce Idling',
        'description': 'Turn off engine if stopped for more than 30 seconds',
        'icon': Icons.timer_off,
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

  Widget _buildErrorWidget(String error) {
    final isIndexError =
        error.contains('failed-precondition') && error.contains('index');

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              isIndexError
                  ? 'Database Configuration Needed'
                  : 'Error loading data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isIndexError ? 'Please contact support if this persists' : error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _navigateToAddFuel(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFuelScreen()),
    );
    setState(() {});
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
  bool _isSubmitting = false;

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
      setState(() {
        _isSubmitting = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('You need to be logged in to add a fuel entry');
        }

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
        setState(() {
          _isSubmitting = false;
        });

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
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('SAVE FUEL ENTRY'),
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
