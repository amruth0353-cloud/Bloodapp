import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class InventoryManagement extends StatelessWidget {
  const InventoryManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Blood Inventory', showBack: false,
        actions: [IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () => _showAddDialog(context))]),
      body: StreamBuilder<List<BloodInventoryModel>>(
        stream: FirestoreService().getInventory(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          final items = snap.data ?? [];
          final totals = <String, int>{};
          for (final item in items) { if (!item.isExpired) totals[item.bloodType] = (totals[item.bloodType] ?? 0) + item.units; }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Inventory Overview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...['A+','A-','B+','B-','AB+','AB-','O+','O-'].map((bt) => InventoryBar(bloodType: bt, units: totals[bt] ?? 0, maxUnits: 50)),
              ]))),
              const SizedBox(height: 16),
              Text('All Blood Units', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (items.isEmpty) EmptyState(icon: Icons.inventory_2_outlined, title: 'No Inventory', subtitle: 'Add blood units to start tracking.',
                action: ElevatedButton.icon(onPressed: () => _showAddDialog(context), icon: const Icon(Icons.add), label: const Text('Add Blood Unit')))
              else ...items.map((item) {
                final expired = item.isExpired;
                final expiring = item.isExpiringSoon && !expired;
                final statusColor = expired ? Colors.grey : expiring ? AppTheme.warningAmber : AppTheme.successGreen;
                final statusLabel = expired ? 'Expired' : expiring ? 'Expiring in ${item.daysUntilExpiry}d' : 'Good';
                return Card(margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(
                  leading: BloodTypeBadge(bloodType: item.bloodType, size: 40),
                  title: Text('${item.units} units — ${item.bloodType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Collected: ${DateFormat('dd MMM yyyy').format(item.collectedAt)}'),
                    Text('Expires: ${DateFormat('dd MMM yyyy').format(item.expiresAt)}', style: TextStyle(color: expired ? Colors.red : Colors.grey)),
                  ]),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600))),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => FirestoreService().removeInventory(item.id)),
                  ]),
                  isThreeLine: true,
                ));
              }),
              const SizedBox(height: 80),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(context), icon: const Icon(Icons.add), label: const Text('Add Blood')),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddInventorySheet());
  }
}

class _AddInventorySheet extends StatefulWidget {
  const _AddInventorySheet();
  @override
  State<_AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends State<_AddInventorySheet> {
  String _bloodType = 'O+';
  int _units = 1;
  DateTime _collectDate = DateTime.now();
  bool _saving = false;
  static const bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];

  Future<void> _submit() async {
    setState(() => _saving = true);
    await FirestoreService().addInventory(BloodInventoryModel(id: '', bloodType: _bloodType, units: _units, collectedAt: _collectDate, expiresAt: _collectDate.add(const Duration(days: 42)), status: 'available'));
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blood unit added to inventory'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Add Blood Unit', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: bloodTypes.map((bt) {
          final sel = _bloodType == bt;
          return InkWell(onTap: () => setState(() => _bloodType = bt), borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 56, height: 40,
              decoration: BoxDecoration(color: sel ? AppTheme.primaryRed : Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? AppTheme.primaryRed : Colors.grey.shade300)),
              child: Center(child: Text(bt, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)))));
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('Units: ', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(onPressed: () => setState(() => _units = (_units - 1).clamp(1, 100)), icon: const Icon(Icons.remove_circle_outline)),
          Text('$_units', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => setState(() => _units = (_units + 1).clamp(1, 100)), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryRed)),
        ]),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now());
            if (d != null) setState(() => _collectDate = d);
          },
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [
              const Icon(Icons.event_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Collection Date', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(DateFormat('dd MMM yyyy').format(_collectDate), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const Spacer(),
              Text('Exp: ${DateFormat('dd MMM yyyy').format(_collectDate.add(const Duration(days: 42)))}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Adding...' : 'Add to Inventory'))),
        const SizedBox(height: 24),
      ]),
    );
  }
}
