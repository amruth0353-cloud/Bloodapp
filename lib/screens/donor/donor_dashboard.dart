import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'notifications_screen.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primaryRed,
            automaticallyImplyLeading: false,
            actions: [
              StreamBuilder(
                stream: FirestoreService().getUserNotifications(user.uid),
                builder: (ctx, snap) {
                  final unread = (snap.data ?? [])
                      .where((n) => !n.isRead)
                      .length;
                  return Badge(
                    isLabelVisible: unread > 0,
                    label: Text(
                      '$unread',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) async {
                  if (v == 'logout') {
                    await context.read<AppProvider>().logout();
                    if (context.mounted)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.deepRed, AppTheme.primaryRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        BloodTypeBadge(bloodType: user.bloodType, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.name.split(' ').first}!',
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${user.bloodType} Donor',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EligibilityCard(user: user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder(
                    stream: FirestoreService().getDonorHistory(user.uid),
                    builder: (ctx, snap) {
                      if (snap.hasError) {
                        return const SizedBox();
                      }
                      final donated = (snap.data ?? [])
                          .where((h) => h.status == 'donated')
                          .length;
                      return Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Donations',
                              value: '$donated',
                              icon: Icons.favorite,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Lives Saved',
                              value: '${donated * 3}',
                              icon: Icons.people,
                              color: AppTheme.successGreen,
                              subtitle: 'estimated',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Active Requests for ${user.bloodType}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StreamBuilder(
                  stream: FirestoreService().getRequestsForBloodType(
                    user.bloodType,
                  ),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.grey,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load requests. Check your connection.',
                                style: Theme.of(ctx).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final requests = snap.data ?? [];
                    if (requests.isEmpty)
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.successGreen,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No active requests right now.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    return Column(
                      children: requests
                          .take(3)
                          .map(
                            (r) => BloodRequestCard(
                              request: r,
                              hasResponded: r.respondedDonors.contains(
                                user.uid,
                              ),
                              onAccept: user.isTimeEligible
                                  ? () async {
                                      try {
                                        await FirestoreService()
                                            .respondToRequest(
                                              r.id,
                                              user.uid,
                                              true,
                                            );
                                        if (ctx.mounted)
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Thank you! The blood bank has been notified.',
                                              ),
                                              backgroundColor:
                                                  AppTheme.successGreen,
                                            ),
                                          );
                                      } catch (e) {
                                        if (ctx.mounted)
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppTheme.primaryRed,
                                            ),
                                          );
                                      }
                                    }
                                  : null,
                              onDecline: user.isTimeEligible
                                  ? () => FirestoreService().respondToRequest(
                                      r.id,
                                      user.uid,
                                      false,
                                    )
                                  : null,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
