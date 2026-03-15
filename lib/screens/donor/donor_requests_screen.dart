import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DonorRequestsScreen extends StatelessWidget {
  const DonorRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Blood Requests', showBack: false),
      body: StreamBuilder(
        stream: FirestoreService().getRequestsForBloodType(user.bloodType),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          final requests = snap.data ?? [];
          if (requests.isEmpty) return const EmptyState(icon: Icons.water_drop_outlined, title: 'No Active Requests', subtitle: 'No blood requests matching your blood type right now.');
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: requests.length,
            itemBuilder: (ctx, i) {
              final r = requests[i];
              final responded = r.respondedDonors.contains(user.uid);
              return BloodRequestCard(
                request: r, hasResponded: responded,
                onAccept: responded ? null : () async {
                  await FirestoreService().respondToRequest(r.id, user.uid, true);
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Thank you! The blood bank will contact you.')));
                },
                onDecline: responded ? null : () => FirestoreService().respondToRequest(r.id, user.uid, false),
              );
            },
          );
        },
      ),
    );
  }
}
