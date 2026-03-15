import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BloodRequestManagement extends StatelessWidget {
  const BloodRequestManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Blood Requests', showBack: false,
        actions: [IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () => _showCreateDialog(context))]),
      body: StreamBuilder(
        stream: FirestoreService().getAllBloodRequests(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          final requests = snap.data ?? [];
          if (requests.isEmpty) return EmptyState(icon: Icons.water_drop_outlined, title: 'No Blood Requests', subtitle: 'Create a blood request to notify eligible donors.',
            action: ElevatedButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('Create Request')));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: requests.length,
            itemBuilder: (ctx, i) => BloodRequestCard(request: requests[i], isAdmin: true,
              onAccept: requests[i].status == 'open' ? () async {
                await FirestoreService().updateRequestStatus(requests[i].id, 'fulfilled');
              } : null),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('New Request')),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CreateRequestSheet());
  }
}

class _CreateRequestSheet extends StatefulWidget {
  const _CreateRequestSheet();
  @override
  State<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<_CreateRequestSheet> {
  final _hospitalCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _bloodType = 'O+', _urgency = 'urgent';
  int _units = 1;
  bool _saving = false;
  static const bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
  static const urgencies = [('standard','Standard',Color(0xFF1565C0)),('urgent','Urgent',Color(0xFFF57C00)),('critical','Critical',Color(0xFFD84315))];

  Future<void> _submit() async {
    if (_hospitalCtrl.text.isEmpty || _locationCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final request = BloodRequestModel(
      id: '', bloodType: _bloodType, unitsNeeded: _units, urgencyLevel: _urgency,
      hospitalName: _hospitalCtrl.text.trim(), location: _locationCtrl.text.trim(),
      adminId: provider.currentUser!.uid, status: 'open',
      respondedDonors: [], confirmedDonors: [], notes: _notesCtrl.text.trim(), createdAt: DateTime.now(),
    );
    final success = await provider.createBloodRequest(request);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Request created! Eligible donors notified.' : 'Failed to create request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Create Blood Request', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text('Blood Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: bloodTypes.map((bt) {
            final sel = _bloodType == bt;
            return InkWell(onTap: () => setState(() => _bloodType = bt), borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 56, height: 40,
                decoration: BoxDecoration(color: sel ? AppTheme.primaryRed : Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? AppTheme.primaryRed : Colors.grey.shade300)),
                child: Center(child: Text(bt, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)))));
          }).toList()),
          const SizedBox(height: 16),
          Text('Urgency', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: urgencies.map((u) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8),
            child: InkWell(onTap: () => setState(() => _urgency = u.$1), borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: _urgency == u.$1 ? u.$3.withOpacity(0.15) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: _urgency == u.$1 ? u.$3 : Colors.grey.shade300, width: _urgency == u.$1 ? 2 : 1)),
                child: Center(child: Text(u.$2, style: TextStyle(color: _urgency == u.$1 ? u.$3 : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)))))
          ))).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Text('Units: ', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(onPressed: () => setState(() => _units = (_units - 1).clamp(1, 50)), icon: const Icon(Icons.remove_circle_outline)),
            Text('$_units', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => setState(() => _units = (_units + 1).clamp(1, 50)), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryRed)),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_outlined))),
          const SizedBox(height: 12),
          TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 12),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_outlined),
            label: Text(_saving ? 'Creating...' : 'Create & Notify Donors'),
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
