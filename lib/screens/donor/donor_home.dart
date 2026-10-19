import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'donor_dashboard.dart';
import 'donor_requests_screen.dart';
import 'donor_appointments_screen.dart';
import 'donor_history_screen.dart';
import 'donor_profile_screen.dart';
import '../shared/chatbot_screen.dart';

class DonorHome extends StatefulWidget {
  const DonorHome({super.key});
  @override
  State<DonorHome> createState() => _DonorHomeState();
}

class _DonorHomeState extends State<DonorHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DonorDashboard(),
    DonorRequestsScreen(),
    DonorAppointmentsScreen(),
    DonorHistoryScreen(),
    DonorProfileScreen(),
  ];

  static const _navItems = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.water_drop_outlined, Icons.water_drop, 'Requests'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Book'),
    (Icons.history_outlined, Icons.history, 'History'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryRed.withValues(alpha: 0.12),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.$1, color: Colors.grey.shade500),
                selectedIcon: Icon(item.$2, color: AppTheme.primaryRed),
                label: item.$3,
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        mini: true,
        tooltip: 'BloodBot AI',
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}
