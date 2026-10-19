import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'donor_list_screen.dart';
import 'inventory_management.dart';
import '../../models/models.dart';

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
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _fs.getAdminStats();
      if (mounted)
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
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
        title: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'BloodConnect Admin',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 18,
              ),
            ),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AppProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(isAdmin: true),
                  ),
                  (_) => false,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryRed, Color(0xFFE53935)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.name ?? 'Administrator',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  title: 'Total Donors',
                                  value: '${_stats['totalDonors'] ?? 0}',
                                  icon: Icons.people_outline,
                                  color: AppTheme.infoBlue,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DonorListScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatsCard(
                                  title: 'Open Requests',
                                  value: '${_stats['openRequests'] ?? 0}',
                                  icon: Icons.water_drop_outlined,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  title: 'Appointments',
                                  value:
                                      '${_stats['upcomingAppointments'] ?? 0}',
                                  icon: Icons.calendar_today_outlined,
                                  color: AppTheme.warningAmber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatsCard(
                                  title: 'Total Donations',
                                  value: '${_stats['totalDonations'] ?? 0}',
                                  icon: Icons.favorite_outline,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              // Inventory Expiry Alert Banner
              StreamBuilder<List<BloodInventoryModel>>(
                stream: _fs.getInventory(),
                builder: (ctx, snap) {
                  final items = snap.data ?? [];
                  final expiring = items
                      .where((i) => i.isExpiringSoon && !i.isExpired)
                      .toList();
                  final expired = items.where((i) => i.isExpired).toList();

                  if (expiring.isEmpty && expired.isEmpty)
                    return const SizedBox();

                  final totalExpiringUnits = expiring.fold<int>(
                    0,
                    (sum, i) => sum + i.units,
                  );
                  final totalExpiredUnits = expired.fold<int>(
                    0,
                    (sum, i) => sum + i.units,
                  );

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: expired.isNotEmpty
                          ? Colors.red.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: expired.isNotEmpty
                            ? Colors.red.shade300
                            : Colors.amber.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          expired.isNotEmpty
                              ? Icons.error_outline
                              : Icons.warning_amber_rounded,
                          color: expired.isNotEmpty
                              ? Colors.red.shade700
                              : Colors.amber.shade900,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expired.isNotEmpty
                                    ? 'Inventory Action Required'
                                    : 'Units Expiring Soon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: expired.isNotEmpty
                                      ? Colors.red.shade900
                                      : Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                expired.isNotEmpty
                                    ? '$totalExpiredUnits expired units need disposal. $totalExpiringUnits expiring soon.'
                                    : '$totalExpiringUnits blood units expire within 7 days.',
                                style: TextStyle(
                                  color: expired.isNotEmpty
                                      ? Colors.red.shade800
                                      : Colors.amber.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventoryManagement(),
                            ),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Requests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: FirestoreService().getOpenBloodRequests(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          );
                        }
                        if (snap.hasError) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Could not load requests',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final requests = (snap.data ?? []).take(3).toList();
                        if (requests.isEmpty)
                          return const EmptyState(
                            icon: Icons.water_drop_outlined,
                            title: 'No Active Requests',
                            subtitle:
                                'Create a blood request to notify donors.',
                          );
                        return Column(
                          children: requests
                              .map(
                                (r) =>
                                    BloodRequestCard(request: r, isAdmin: true),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
