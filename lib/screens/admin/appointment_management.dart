import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AppointmentManagement extends StatelessWidget {
  const AppointmentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Appointments', showBack: false,
        actions: [IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () => _showCreateSheet(context))]),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: FirestoreService().getAllAppointments(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          final appointments = snap.data ?? [];
          if (appointments.isEmpty) return EmptyState(icon: Icons.calendar_month_outlined, title: 'No Appointments', subtitle: 'Schedule donation slots for donors to book.',
            action: ElevatedButton.icon(onPressed: () => _showCreateSheet(context), icon: const Icon(Icons.add), label: const Text('Add Slot')));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (ctx, i) {
              final apt = appointments[i];
              final isUpcoming = apt.date.isAfter(DateTime.now());
              final fillFraction = apt.maxCapacity > 0 ? apt.bookedDonors.length / apt.maxCapacity : 0.0;
              return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: isUpcoming ? AppTheme.primaryRed.withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat('dd').format(apt.date), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isUpcoming ? AppTheme.primaryRed : Colors.grey)),
                    Text(DateFormat('MMM').format(apt.date), style: TextStyle(fontSize: 11, color: isUpcoming ? AppTheme.primaryRed : Colors.grey)),
                  ]),
                ),
                title: Text(apt.timeSlot, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(apt.location, style: const TextStyle(fontSize: 12)))]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: fillFraction, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(fillFraction > 0.9 ? AppTheme.primaryRed : AppTheme.successGreen), minHeight: 6))),
                    const SizedBox(width: 8),
                    Text('${apt.bookedDonors.length}/${apt.maxCapacity}', style: const TextStyle(fontSize: 12)),
                  ]),
                ]),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => FirestoreService().deleteAppointment(apt.id)),
                isThreeLine: true,
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showCreateSheet(context), icon: const Icon(Icons.add), label: const Text('Add Slot')),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CreateAppointmentSheet());
  }
}

class _CreateAppointmentSheet extends StatefulWidget {
  const _CreateAppointmentSheet();
  @override
  State<_CreateAppointmentSheet> createState() => _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState extends State<_CreateAppointmentSheet> {
  final _locationCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  int _capacity = 10;
  bool _saving = false;

  Future<void> _submit() async {
    if (_locationCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final apt = AppointmentModel(
      id: '', date: _selectedDate,
      timeSlot: '${_startTime.format(context)} - ${_endTime.format(context)}',
      location: _locationCtrl.text.trim(), maxCapacity: _capacity,
      bookedDonors: [], adminId: context.read<AppProvider>().currentUser!.uid, status: 'open',
    );
    await FirestoreService().createAppointment(apt);
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment slot created'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Add Donation Slot', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
            if (d != null) setState(() => _selectedDate = d);
          },
          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [const Icon(Icons.event_outlined, color: Colors.grey), const SizedBox(width: 8), Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600))])),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: InkWell(
            onTap: () async { final t = await showTimePicker(context: context, initialTime: _startTime); if (t != null) setState(() => _startTime = t); },
            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [const Icon(Icons.access_time_outlined, color: Colors.grey, size: 18), const SizedBox(width: 8), Text(_startTime.format(context))])),
          )),
          const SizedBox(width: 12),
          Expanded(child: InkWell(
            onTap: () async { final t = await showTimePicker(context: context, initialTime: _endTime); if (t != null) setState(() => _endTime = t); },
            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [const Icon(Icons.access_time_filled_outlined, color: Colors.grey, size: 18), const SizedBox(width: 8), Text(_endTime.format(context))])),
          )),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location / Venue', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        Row(children: [
          Text('Max Donors: ', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(onPressed: () => setState(() => _capacity = (_capacity - 1).clamp(1, 100)), icon: const Icon(Icons.remove_circle_outline)),
          Text('$_capacity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => setState(() => _capacity = (_capacity + 1).clamp(1, 100)), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryRed)),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Creating...' : 'Create Slot'))),
        const SizedBox(height: 24),
      ]),
    );
  }
}
