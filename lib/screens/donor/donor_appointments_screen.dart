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
          title: const Text('Appointments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
            tabs: [Tab(text: 'Available Slots'), Tab(text: 'My Bookings')],
          ),
        ),
        body: TabBarView(children: [_AvailableSlots(userId: user.uid), _MyBookings(userId: user.uid)]),
      ),
    );
  }
}

class _AvailableSlots extends StatelessWidget {
  final String userId;
  const _AvailableSlots({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: FirestoreService().getUpcomingAppointments(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
        final slots = snap.data ?? [];
        if (slots.isEmpty) return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No Available Slots', subtitle: 'No donation slots scheduled yet. Check back soon.');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          itemBuilder: (ctx, i) {
            final apt = slots[i];
            final alreadyBooked = apt.bookedDonors.contains(userId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: apt.isFull ? Colors.grey.shade100 : AppTheme.softPink, borderRadius: BorderRadius.circular(10)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(DateFormat('dd').format(apt.date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: apt.isFull ? Colors.grey : AppTheme.primaryRed)),
                        Text(DateFormat('MMM').format(apt.date), style: TextStyle(fontSize: 12, color: apt.isFull ? Colors.grey : AppTheme.primaryRed)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(apt.timeSlot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 2), Expanded(child: Text(apt.location, style: const TextStyle(fontSize: 13, color: Colors.grey)))]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(apt.isFull ? 'Full' : '${apt.availableSlots} left', style: TextStyle(color: apt.isFull ? Colors.grey : AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('of ${apt.maxCapacity}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: alreadyBooked
                        ? OutlinedButton.icon(
                            onPressed: () async { await FirestoreService().cancelBooking(apt.id, userId); },
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                            label: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          )
                        : ElevatedButton.icon(
                            onPressed: apt.isFull ? null : () async {
                              try {
                                await FirestoreService().bookAppointment(apt.id, userId);
                                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Appointment booked! See you there.')));
                              } catch (e) {
                                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            },
                            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            label: Text(apt.isFull ? 'Fully Booked' : 'Book This Slot'),
                          ),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyBookings extends StatelessWidget {
  final String userId;
  const _MyBookings({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppointmentModel>>(
      future: FirestoreService().getDonorAppointments(userId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) return const EmptyState(icon: Icons.event_busy_outlined, title: 'No Bookings Yet', subtitle: 'Book an available slot to schedule your next donation.');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (ctx, i) {
            final apt = bookings[i];
            final isPast = apt.date.isBefore(DateTime.now());
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPast ? Colors.grey.shade200 : AppTheme.primaryRed.withOpacity(0.15),
                  child: Icon(isPast ? Icons.check : Icons.event_available, color: isPast ? Colors.grey : AppTheme.primaryRed),
                ),
                title: Text(DateFormat('EEEE, dd MMM yyyy').format(apt.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${apt.timeSlot}\n${apt.location}'),
                trailing: isPast ? const Chip(label: Text('Past', style: TextStyle(fontSize: 11)))
                    : OutlinedButton(
                        onPressed: () => FirestoreService().cancelBooking(apt.id, userId),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
