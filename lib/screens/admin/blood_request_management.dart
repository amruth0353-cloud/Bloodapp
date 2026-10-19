import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class BloodRequestManagement extends StatefulWidget {
  const BloodRequestManagement({super.key});

  @override
  State<BloodRequestManagement> createState() => _BloodRequestManagementState();
}

class _BloodRequestManagementState extends State<BloodRequestManagement> {
  String _selectedBloodType = 'All';
  String _selectedStatus = 'All';
  String _selectedUrgency = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(
        title: 'Blood Requests',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'New Request',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blood types filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', ...AppConstants.bloodTypes].map((bt) {
                      final isSelected = _selectedBloodType == bt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(bt),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedBloodType = bt),
                          selectedColor: AppTheme.primaryRed.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: AppTheme.primaryRed,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryRed
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),

                // Status & Urgency row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Status filters
                      ...['All', 'open', 'fulfilled', 'cancelled'].map((
                        status,
                      ) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(status.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedStatus = status),
                            selectedColor: Colors.grey.shade800,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      // Urgency filters
                      ...['critical', 'urgent', 'standard'].map((urg) {
                        final isSelected = _selectedUrgency == urg;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(urg.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) => setState(
                              () => _selectedUrgency = isSelected ? 'All' : urg,
                            ),
                            selectedColor: urg == 'critical'
                                ? Colors.red
                                : urg == 'urgent'
                                ? Colors.orange
                                : Colors.blue,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Requests list
          Expanded(
            child: StreamBuilder<List<BloodRequestModel>>(
              stream: FirestoreService().getAllBloodRequests(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }
                if (snap.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Could not load blood requests. Check connection.',
                        ),
                      ],
                    ),
                  );
                }

                var requests = snap.data ?? [];

                // Filter by blood type
                if (_selectedBloodType != 'All') {
                  requests = requests
                      .where((r) => r.bloodType == _selectedBloodType)
                      .toList();
                }

                // Filter by status
                if (_selectedStatus != 'All') {
                  requests = requests
                      .where((r) => r.status == _selectedStatus)
                      .toList();
                }

                // Filter by urgency
                if (_selectedUrgency != 'All') {
                  requests = requests
                      .where((r) => r.urgencyLevel == _selectedUrgency)
                      .toList();
                }

                if (requests.isEmpty) {
                  return EmptyState(
                    icon: Icons.water_drop_outlined,
                    title: 'No Matching Requests',
                    subtitle:
                        'Try changing your filter options or create a new request.',
                    action: ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Request'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: requests.length,
                  itemBuilder: (ctx, i) => BloodRequestCard(
                    request: requests[i],
                    isAdmin: true,
                    onEdit: () => _showEditDialog(context, requests[i]),
                    onDelete: () => _confirmDelete(context, requests[i]),
                    onAccept: requests[i].status == 'open'
                        ? () async {
                            await FirestoreService().updateRequestStatus(
                              requests[i].id,
                              'fulfilled',
                            );
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateRequestSheet(),
    );
  }

  void _showEditDialog(BuildContext context, BloodRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateRequestSheet(request: request),
    );
  }

  void _confirmDelete(BuildContext context, BloodRequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text(
          'Are you sure you want to delete this blood request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteBloodRequest(request.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CreateRequestSheet extends StatefulWidget {
  final BloodRequestModel? request;
  const _CreateRequestSheet({this.request});
  @override
  State<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<_CreateRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _bloodType;
  late String _urgency;
  late int _units;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _locationCtrl;
  DateTime? _requiredByDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    _bloodType = r?.bloodType ?? 'A+';
    _urgency = r?.urgencyLevel ?? 'standard';
    _units = r?.unitsNeeded ?? 1;
    _hospitalCtrl = TextEditingController(text: r?.hospitalName ?? '');
    _locationCtrl = TextEditingController(text: r?.location ?? '');
    _requiredByDate = r?.requiredBy;
  }

  @override
  void dispose() {
    _hospitalCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = context.read<AppProvider>().currentUser;

    final req = BloodRequestModel(
      id: widget.request?.id ?? '',
      bloodType: _bloodType,
      unitsNeeded: _units,
      urgencyLevel: _urgency,
      hospitalName: _hospitalCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      requiredBy: _requiredByDate,
      createdAt: widget.request?.createdAt ?? DateTime.now(),
      status: widget.request?.status ?? 'open',
      adminId: user?.uid ?? '',
      respondedDonors: widget.request?.respondedDonors ?? [],
      confirmedDonors: widget.request?.confirmedDonors ?? [],
      completedDonors: widget.request?.completedDonors ?? [],
      notes: widget.request?.notes ?? '',
    );

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (widget.request == null) {
      await context.read<AppProvider>().createBloodRequest(req);
    } else {
      await context.read<AppProvider>().updateBloodRequest(req);
    }

    if (mounted) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.request == null
                ? 'Blood request broadcasted to donors!'
                : 'Request updated!',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.request == null
                    ? 'Create Blood Request'
                    : 'Edit Blood Request',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text('Blood Type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.bloodTypes.map((bt) {
                  final sel = _bloodType == bt;
                  return ChoiceChip(
                    label: Text(bt),
                    selected: sel,
                    onSelected: (_) => setState(() => _bloodType = bt),
                    selectedColor: AppTheme.primaryRed,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Urgency Level',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children:
                    [
                      ('standard', 'Standard', AppTheme.infoBlue),
                      ('urgent', 'Urgent', AppTheme.warningAmber),
                      ('critical', 'Critical', AppTheme.primaryRed),
                    ].map((u) {
                      final sel = _urgency == u.$1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(u.$2),
                            selected: sel,
                            onSelected: (_) => setState(() => _urgency = u.$1),
                            selectedColor: u.$3,
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Units Needed: ',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _units = (_units - 1).clamp(1, 50)),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  Text(
                    '$_units',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _units = (_units + 1).clamp(1, 50)),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hospitalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _requiredByDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null && mounted) {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _requiredByDate != null
                          ? TimeOfDay.fromDateTime(_requiredByDate!)
                          : TimeOfDay.now(),
                    );
                    if (mounted) {
                      if (t != null) {
                        setState(
                          () => _requiredByDate = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t.hour,
                            t.minute,
                          ),
                        );
                      } else {
                        setState(() => _requiredByDate = d);
                      }
                    }
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Required By (optional)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _requiredByDate != null
                        ? DateFormat('MMMd').add_jm().format(_requiredByDate!)
                        : 'Select Date & Time',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.request == null
                              ? 'Broadcast Request'
                              : 'Save Changes',
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
