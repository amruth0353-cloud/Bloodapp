import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../shared/education_screen.dart';

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
