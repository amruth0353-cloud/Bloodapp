import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: const BloodConnectAppBar(title: 'Notifications', showBack: true),
      body: StreamBuilder<List<AppNotification>>(
        stream: FirestoreService().getUserNotifications(user.uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          }
          final notifications = snap.data ?? [];
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              subtitle: 'You are all caught up!',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final n = notifications[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: n.type == 'blood_request' 
                      ? AppTheme.primaryRed.withValues(alpha: 0.1) 
                      : AppTheme.successGreen.withValues(alpha: 0.1),
                  child: Icon(
                    n.type == 'blood_request' ? Icons.water_drop : Icons.info_outline,
                    color: n.type == 'blood_request' ? AppTheme.primaryRed : AppTheme.successGreen,
                  ),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(n.body),
                trailing: n.isRead ? null : const Icon(Icons.circle, size: 10, color: AppTheme.primaryRed),
              );
            },
          );
        },
      ),
    );
  }
}
