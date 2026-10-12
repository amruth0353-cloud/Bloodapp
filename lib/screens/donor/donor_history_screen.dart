import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DonorHistoryScreen extends StatelessWidget {
  const DonorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Donation History', showBack: false),
      body: SingleChildScrollView(child: Column(children: [
        EligibilityCard(user: user),
        StreamBuilder(
          stream: FirestoreService().getDonorHistory(user.uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryRed)));
            final history = snap.data ?? [];
            if (history.isEmpty) return const EmptyState(icon: Icons.history_edu_outlined, title: 'No Donation History', subtitle: 'Your donation records will appear here after your first donation.');
            return Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                Text('Donation Records', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('${history.length} records', style: Theme.of(context).textTheme.bodySmall),
              ])),
              const SizedBox(height: 8),
              ...history.map((h) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: h.status == 'donated' ? AppTheme.successGreen.withValues(alpha: 0.15) : Colors.grey.shade100,
                    child: Icon(h.status == 'donated' ? Icons.favorite : Icons.cancel_outlined, color: h.status == 'donated' ? AppTheme.successGreen : Colors.grey, size: 22),
                  ),
                  title: Text(DateFormat('dd MMM yyyy').format(h.donationDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.location),
                    Text('Health: ${h.healthStatus}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: h.status == 'donated' ? AppTheme.successGreen.withValues(alpha: 0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(h.status == 'donated' ? 'Donated' : 'Deferred', style: TextStyle(color: h.status == 'donated' ? AppTheme.successGreen : Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  isThreeLine: true,
                ),
              )),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ])),
    );
  }
}
