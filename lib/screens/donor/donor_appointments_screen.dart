import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DonorAppointmentsScreen extends StatelessWidget {
  const DonorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryRed,
          automaticallyImplyLeading: false,
          title: const Text(
            'Appointments',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Available Slots'),
              Tab(text: 'My Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AvailableSlots(userId: user.uid),
            _MyBookings(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

class _AvailableSlots extends StatefulWidget {
  final String userId;
  const _AvailableSlots({required this.userId});

  @override
  State<_AvailableSlots> createState() => _AvailableSlotsState();
}

class _AvailableSlotsState extends State<_AvailableSlots> {
  final Set<String> _loadingIds = {};

  Future<void> _handleBook(AppointmentModel apt) async {
    setState(() => _loadingIds.add(apt.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService().bookAppointment(apt.id, widget.userId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Appointment booked! See you there.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(apt.id));
    }
  }

  Future<void> _handleCancel(AppointmentModel apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel your booking for ${DateFormat('dd MMM').format(apt.date)} at ${apt.timeSlot}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loadingIds.add(apt.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService().cancelBooking(apt.id, widget.userId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Appointment booking cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not cancel: ${e.toString()}'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(apt.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: FirestoreService().getUpcomingAppointments(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }
        if (snap.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text('Could not load appointment slots. Check connection.'),
              ],
            ),
          );
        }

        final slots = snap.data ?? [];
        if (slots.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No Available Slots',
            subtitle: 'No donation slots scheduled yet. Check back soon.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          itemBuilder: (ctx, i) {
            final apt = slots[i];
            final alreadyBooked = apt.bookedDonors.contains(widget.userId);
            final isLoading = _loadingIds.contains(apt.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: apt.isFull
                                ? Colors.grey.shade100
                                : AppTheme.softPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('dd').format(apt.date),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: apt.isFull
                                      ? Colors.grey
                                      : AppTheme.primaryRed,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(apt.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: apt.isFull
                                      ? Colors.grey
                                      : AppTheme.primaryRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apt.timeSlot,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      apt.location,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              apt.isFull
                                  ? 'Full'
                                  : '${apt.availableSlots} left',
                              style: TextStyle(
                                color: apt.isFull
                                    ? Colors.grey
                                    : AppTheme.successGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'of ${apt.maxCapacity}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: alreadyBooked
                          ? OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => _handleCancel(apt),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.red,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                              label: Text(
                                isLoading ? 'Cancelling...' : 'Cancel Booking',
                                style: const TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: (apt.isFull || isLoading)
                                  ? null
                                  : () => _handleBook(apt),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                isLoading
                                    ? 'Booking...'
                                    : (apt.isFull
                                          ? 'Fully Booked'
                                          : 'Book This Slot'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyBookings extends StatefulWidget {
  final String userId;
  const _MyBookings({required this.userId});

  @override
  State<_MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<_MyBookings> {
  late Future<List<AppointmentModel>> _bookingsFuture;
  final Set<String> _cancellingIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    _bookingsFuture = FirestoreService().getDonorAppointments(widget.userId);
  }

  Future<void> _cancelBooking(AppointmentModel apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel your donation appointment for ${DateFormat('dd MMM').format(apt.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Appointment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _cancellingIds.add(apt.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService().cancelBooking(apt.id, widget.userId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Appointment cancelled.')),
        );
        setState(() {
          _cancellingIds.remove(apt.id);
          _loadBookings();
        });
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _cancellingIds.remove(apt.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppointmentModel>>(
      future: _bookingsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }
        if (snap.hasError) {
          return const Center(
            child: Text('Could not load bookings. Please pull down to retry.'),
          );
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No Bookings Yet',
            subtitle: 'Book an available slot to schedule your next donation.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _loadBookings()),
          color: AppTheme.primaryRed,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (ctx, i) {
              final apt = bookings[i];
              final isPast = apt.date.isBefore(DateTime.now());
              final isCancelling = _cancellingIds.contains(apt.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPast
                        ? Colors.grey.shade200
                        : AppTheme.primaryRed.withValues(alpha: 0.15),
                    child: Icon(
                      isPast ? Icons.check : Icons.event_available,
                      color: isPast ? Colors.grey : AppTheme.primaryRed,
                    ),
                  ),
                  title: Text(
                    DateFormat('EEEE, dd MMM yyyy').format(apt.date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${apt.timeSlot}\n${apt.location}'),
                  trailing: isPast
                      ? const Chip(
                          label: Text('Past', style: TextStyle(fontSize: 11)),
                        )
                      : OutlinedButton(
                          onPressed: isCancelling
                              ? null
                              : () => _cancelBooking(apt),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: isCancelling
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
                        ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
