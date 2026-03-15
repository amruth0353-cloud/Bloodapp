import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final inv = await _fs.getInventorySummary();
    if (mounted) setState(() { _inventorySummary = inv; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Analytics', showBack: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Blood Inventory by Type', style: Theme.of(context).textTheme.titleLarge),
                    Text('Available units per blood group', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    SizedBox(height: 220, child: _buildInventoryChart()),
                  ]))),
                  const SizedBox(height: 16),
                  StreamBuilder(
                    stream: _fs.getAllBloodRequests(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final requests = snap.data!;
                      final sc = <String, int>{'open': 0, 'fulfilled': 0, 'cancelled': 0};
                      for (final r in requests) sc[r.status] = (sc[r.status] ?? 0) + 1;
                      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Blood Requests by Status', style: Theme.of(context).textTheme.titleLarge),
                        Text('${requests.length} total requests', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                        const SizedBox(height: 16),
                        ...[('Open', sc['open']??0, AppTheme.primaryRed), ('Fulfilled', sc['fulfilled']??0, AppTheme.successGreen), ('Cancelled', sc['cancelled']??0, Colors.grey)].map((item) =>
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                            SizedBox(width: 80, child: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: requests.isNotEmpty ? item.$2/requests.length : 0, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(item.$3), minHeight: 12))),
                            const SizedBox(width: 8),
                            Text('${item.$2}', style: TextStyle(fontWeight: FontWeight.bold, color: item.$3)),
                          ]))
                        ),
                      ])));
                    },
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
    );
  }

  Widget _buildInventoryChart() {
    final bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
    final colors = [AppTheme.primaryRed, const Color(0xFFE57373), AppTheme.infoBlue, const Color(0xFF64B5F6), AppTheme.warningAmber, const Color(0xFFFFB74D), AppTheme.successGreen, const Color(0xFF81C784)];
    final bars = bloodTypes.asMap().entries.map((e) {
      final units = (_inventorySummary[e.value] ?? 0).toDouble();
      return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: units == 0 ? 0.5 : units, color: units == 0 ? Colors.grey.shade300 : colors[e.key], width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
    }).toList();
    return BarChart(BarChartData(
      barGroups: bars,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(bloodTypes[v.toInt()], style: const TextStyle(fontSize: 11))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, _, rod, __) => BarTooltipItem('${bloodTypes[group.x]}\n${rod.toY.toInt()} units', GoogleFonts.poppins(color: Colors.white, fontSize: 12)))),
    ));
  }
}
