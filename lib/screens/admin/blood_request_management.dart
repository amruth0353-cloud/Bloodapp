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
              onEdit: () => _showEditDialog(context, requests[i]),
              onDelete: () => _confirmDelete(context, requests[i]),
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

  void _showEditDialog(BuildContext context, BloodRequestModel request) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateRequestSheet(request: request));
  }

  void _confirmDelete(BuildContext context, BloodRequestModel request) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Request?'),
      content: const Text('Are you sure you want to delete this blood request? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          final provider = context.read<AppProvider>();
          final success = await provider.deleteBloodRequest(request.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Request deleted.' : 'Failed to delete request.')));
          }
        }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
      ],
    ));
  }
}

class _CreateRequestSheet extends StatefulWidget {
  final BloodRequestModel? request;
  const _CreateRequestSheet({this.request});
  @override
  State<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<_CreateRequestSheet> {
  final _hospitalCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _bloodType = 'O+', _urgency = 'urgent';
  int _units = 1;
  DateTime? _requiredByDate;
  bool _saving = false;
  static const bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
  static const urgencies = [('standard','Standard',Color(0xFF1565C0)),('urgent','Urgent',Color(0xFFF57C00)),('critical','Critical',Color(0xFFD84315))];

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _hospitalCtrl.text = widget.request!.hospitalName;
      _locationCtrl.text = widget.request!.location;
      _notesCtrl.text = widget.request!.notes;
      _bloodType = widget.request!.bloodType;
      _urgency = widget.request!.urgencyLevel;
      _units = widget.request!.unitsNeeded;
      _requiredByDate = widget.request!.requiredBy;
    }
  }

  Future<void> _submit() async {
    if (_hospitalCtrl.text.isEmpty || _locationCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final request = BloodRequestModel(
      id: widget.request?.id ?? '', bloodType: _bloodType, unitsNeeded: _units, urgencyLevel: _urgency,
      hospitalName: _hospitalCtrl.text.trim(), location: _locationCtrl.text.trim(),
      adminId: provider.currentUser!.uid, status: widget.request?.status ?? 'open',
      respondedDonors: widget.request?.respondedDonors ?? [], confirmedDonors: widget.request?.confirmedDonors ?? [], notes: _notesCtrl.text.trim(), createdAt: widget.request?.createdAt ?? DateTime.now(),
      requiredBy: _requiredByDate,
      completedDonors: widget.request?.completedDonors ?? [],
    );
    final success = widget.request == null
        ? await provider.createBloodRequest(request)
        : await provider.updateBloodRequest(request);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? (widget.request == null ? 'Request created! Eligible donors notified.' : 'Request updated!') : 'Failed to save request')));
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
          Text(widget.request == null ? 'Create Blood Request' : 'Edit Blood Request', style: Theme.of(context).textTheme.headlineMedium),
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
                decoration: BoxDecoration(color: _urgency == u.$1 ? u.$3.withValues(alpha: 0.15) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: _urgency == u.$1 ? u.$3 : Colors.grey.shade300, width: _urgency == u.$1 ? 2 : 1)),
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
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _requiredByDate ?? DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) {
                if (!mounted) return;
                final t = await showTimePicker(context: context, initialTime: _requiredByDate != null ? TimeOfDay.fromDateTime(_requiredByDate!) : TimeOfDay.now());
                if (t != null) {
                  setState(() => _requiredByDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                } else {
                  setState(() => _requiredByDate = d);
                }
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Required By (optional)', prefixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(_requiredByDate != null ? DateFormat('MMMd').add_jm().format(_requiredByDate!) : 'Select Date & Time'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : (widget.request == null ? const Icon(Icons.send_outlined) : const Icon(Icons.save_outlined)),
            label: Text(_saving ? 'Saving...' : (widget.request == null ? 'Create & Notify Donors' : 'Save Changes')),
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
