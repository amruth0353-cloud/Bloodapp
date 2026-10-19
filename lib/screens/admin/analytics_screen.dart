import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _fs = FirestoreService();
  Map<String, int> _inventorySummary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final inv = await _fs.getInventorySummary();
      if (mounted)
        setState(() {
          _inventorySummary = inv;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Analytics & Reports', showBack: false),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood Inventory Bar Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blood Inventory by Type',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Available units in stock per blood group',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: _buildInventoryChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Donations Over Time Line Chart
                    StreamBuilder<List<DonationHistoryModel>>(
                      stream: _fs.getAllHistory(),
                      builder: (ctx, snap) {
                        if (snap.hasError) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Could not load donation history trends.',
                              ),
                            ),
                          );
                        }
                        final history = snap.data ?? [];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Donation Trends (Last 6 Months)',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Number of completed donations over time',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildDonationsLineChart(history),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Requests by status
                    StreamBuilder<List<BloodRequestModel>>(
                      stream: _fs.getAllBloodRequests(),
                      builder: (ctx, snap) {
                        if (snap.hasError) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Error loading requests data.'),
                            ),
                          );
                        }
                        if (!snap.hasData) return const SizedBox();
                        final requests = snap.data!;
                        final sc = <String, int>{
                          'open': 0,
                          'fulfilled': 0,
                          'cancelled': 0,
                        };
                        for (final r in requests) {
                          sc[r.status] = (sc[r.status] ?? 0) + 1;
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Blood Requests by Status',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${requests.length} total recorded requests',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 16),
                                ...[
                                  (
                                    'Open Requests',
                                    sc['open'] ?? 0,
                                    AppTheme.primaryRed,
                                  ),
                                  (
                                    'Fulfilled Requests',
                                    sc['fulfilled'] ?? 0,
                                    AppTheme.successGreen,
                                  ),
                                  (
                                    'Cancelled',
                                    sc['cancelled'] ?? 0,
                                    Colors.grey,
                                  ),
                                ].map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 130,
                                          child: Text(
                                            item.$1,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: requests.isNotEmpty
                                                  ? item.$2 / requests.length
                                                  : 0,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    item.$3,
                                                  ),
                                              minHeight: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${item.$2}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: item.$3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInventoryChart() {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final colors = [
      AppTheme.primaryRed,
      const Color(0xFFE57373),
      AppTheme.infoBlue,
      const Color(0xFF64B5F6),
      AppTheme.warningAmber,
      const Color(0xFFFFB74D),
      AppTheme.successGreen,
      const Color(0xFF81C784),
    ];

    final bars = bloodTypes.asMap().entries.map((e) {
      final units = (_inventorySummary[e.value] ?? 0).toDouble();
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: units == 0 ? 0.5 : units,
            color: units == 0 ? Colors.grey.shade300 : colors[e.key],
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  bloodTypes[v.toInt()],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${bloodTypes[group.x]}\n${rod.toY.toInt()} units',
              GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationsLineChart(List<DonationHistoryModel> history) {
    // Generate the last 6 months list
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    // Count completed donations for each month
    final monthlyCounts = <int, int>{};
    for (int i = 0; i < 6; i++) {
      monthlyCounts[i] = 0;
    }

    for (final h in history) {
      if (h.status != 'donated') continue;
      for (int i = 0; i < 6; i++) {
        final m = months[i];
        if (h.donationDate.year == m.year && h.donationDate.month == m.month) {
          monthlyCounts[i] = (monthlyCounts[i] ?? 0) + 1;
          break;
        }
      }
    }

    final spots = List.generate(6, (i) {
      return FlSpot(i.toDouble(), (monthlyCounts[i] ?? 0).toDouble());
    });

    final maxY =
        monthlyCounts.values
            .fold<int>(5, (max, v) => v > max ? v : max)
            .toDouble() +
        2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= 6) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM').format(months[idx]),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryRed.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
