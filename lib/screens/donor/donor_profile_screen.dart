import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../shared/education_screen.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'My Profile', showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
            CircleAvatar(radius: 36, backgroundColor: AppTheme.primaryRed, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              Text(user.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              BloodTypeBadge(bloodType: user.bloodType, size: 32),
            ])),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Personal Details', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 16),
            ...[('Age', '${user.age} years'), ('Gender', user.gender), ('Phone', user.phone), ('Blood Type', user.bloodType)].map((item) =>
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                SizedBox(width: 90, child: Text(item.$1, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
              ]))
            ),
          ]))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Donation Eligibility', style: Theme.of(context).textTheme.titleMedium),
              StreamBuilder<bool>(
                stream: FirestoreService().hasActiveRequest(user.uid),
                builder: (context, snapshot) {
                  final hasActive = snapshot.data ?? false;
                  final isTimeEligible = user.lastDonationDate == null || DateTime.now().isAfter(user.lastDonationDate!.add(const Duration(days: 56)));
                  final isEligible = isTimeEligible && !hasActive;
                  
                  final text = hasActive ? 'Currently Responding' : (isEligible ? 'Eligible' : 'Not Eligible');
                  final color = isEligible ? AppTheme.successGreen : Colors.orange;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ]),
            const Divider(height: 16),
            if (user.lastDonationDate != null) ...[
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                const SizedBox(width: 140, child: Text('Last Donation', style: TextStyle(color: Colors.grey, fontSize: 13))),
                Text(DateFormat.yMMMd().format(user.lastDonationDate!), style: const TextStyle(fontWeight: FontWeight.w500)),
              ])),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                const SizedBox(width: 140, child: Text('Next Eligible Date', style: TextStyle(color: Colors.grey, fontSize: 13))),
                Text(DateFormat.yMMMd().format(user.lastDonationDate!.add(const Duration(days: 56))), style: const TextStyle(fontWeight: FontWeight.w500)),
              ])),
            ] else
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('No previous donations recorded. You are eligible to donate!')),
          ]))),
          const SizedBox(height: 12),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Educational Resources'), trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationScreen()))),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              onTap: () async {
                await context.read<AppProvider>().logout();
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }),
          ])),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
