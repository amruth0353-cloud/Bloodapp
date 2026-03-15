import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _fs = FirestoreService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    try {
      final stats = await _fs.getAdminStats();
      if (mounted) setState(() { _stats = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text('BloodConnect Admin', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(backgroundColor: Colors.white24, radius: 16, child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 18)),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AppProvider>().logout();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen(isAdmin: true)), (_) => false);
              }
            },
            itemBuilder: (_) => [const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))]))],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryRed, Color(0xFFE53935)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                Text(user?.name ?? 'Administrator', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingStats
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryRed)))
                  : Column(children: [
                      Row(children: [
                        Expanded(child: StatsCard(title: 'Total Donors', value: '${_stats['totalDonors'] ?? 0}', icon: Icons.people_outline, color: AppTheme.infoBlue)),
                        const SizedBox(width: 12),
                        Expanded(child: StatsCard(title: 'Open Requests', value: '${_stats['openRequests'] ?? 0}', icon: Icons.water_drop_outlined, color: AppTheme.primaryRed)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: StatsCard(title: 'Appointments', value: '${_stats['upcomingAppointments'] ?? 0}', icon: Icons.calendar_today_outlined, color: AppTheme.warningAmber)),
                        const SizedBox(width: 12),
                        Expanded(child: StatsCard(title: 'Total Donations', value: '${_stats['totalDonations'] ?? 0}', icon: Icons.favorite_outline, color: AppTheme.successGreen)),
                      ]),
                    ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Recent Requests', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                StreamBuilder(
                  stream: FirestoreService().getOpenBloodRequests(),
                  builder: (ctx, snap) {
                    final requests = (snap.data ?? []).take(3).toList();
                    if (requests.isEmpty) return const EmptyState(icon: Icons.water_drop_outlined, title: 'No Active Requests', subtitle: 'Create a blood request to notify donors.');
                    return Column(children: requests.map((r) => BloodRequestCard(request: r, isAdmin: true)).toList());
                  },
                ),
              ]),
            ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }
}
