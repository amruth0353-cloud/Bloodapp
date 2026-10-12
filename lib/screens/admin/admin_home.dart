import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard.dart';
import 'blood_request_management.dart';
import 'inventory_management.dart';
import 'appointment_management.dart';
import 'analytics_screen.dart';
import '../shared/chatbot_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboard(),
    BloodRequestManagement(),
    InventoryManagement(),
    AppointmentManagement(),
    AnalyticsScreen(),
  ];

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.water_drop_outlined, Icons.water_drop, 'Requests'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Inventory'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Schedule'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics'),
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
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.$1, color: Colors.grey.shade500),
          selectedIcon: Icon(item.$2, color: AppTheme.primaryRed),
          label: item.$3,
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        mini: true,
        tooltip: 'AI Assistant',
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}
