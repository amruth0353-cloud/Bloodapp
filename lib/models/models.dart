import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bloodType;
  final int age;
  final String gender;
  final String role;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastDonationDate;

  const UserModel({
    required this.uid, required this.name, required this.email,
    required this.phone, required this.bloodType, required this.age,
    required this.gender, required this.role, this.fcmToken,
    required this.createdAt, this.lastDonationDate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, name: d['name'] ?? '', email: d['email'] ?? '',
      phone: d['phone'] ?? '', bloodType: d['bloodType'] ?? '',
      age: d['age'] ?? 0, gender: d['gender'] ?? '',
      role: d['role'] ?? 'donor', fcmToken: d['fcmToken'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastDonationDate: (d['lastDonationDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'email': email, 'phone': phone,
    'bloodType': bloodType, 'age': age, 'gender': gender,
    'role': role, 'fcmToken': fcmToken,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastDonationDate': lastDonationDate != null ? Timestamp.fromDate(lastDonationDate!) : null,
  };

  bool get isTimeEligible => lastDonationDate == null || DateTime.now().isAfter(lastDonationDate!.add(const Duration(days: 90)));
  DateTime? get nextEligibleDate => lastDonationDate?.add(const Duration(days: 90));
}

class BloodRequestModel {
  final String id;
  final String bloodType;
  final int unitsNeeded;
  final String urgencyLevel;
  final String hospitalName;
  final String location;
  final String adminId;
  final String status;
  final List<String> respondedDonors;
  final List<String> confirmedDonors;
  final List<String> completedDonors;
  final String notes;
  final DateTime createdAt;
  final DateTime? requiredBy;

  const BloodRequestModel({
    required this.id, required this.bloodType, required this.unitsNeeded,
    required this.urgencyLevel, required this.hospitalName,
    required this.location, required this.adminId, required this.status,
    required this.respondedDonors, required this.confirmedDonors,
    this.completedDonors = const [], required this.notes, required this.createdAt, this.requiredBy,
  });

  factory BloodRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BloodRequestModel(
      id: doc.id, bloodType: d['bloodType'] ?? '',
      unitsNeeded: d['unitsNeeded'] ?? 1,
      urgencyLevel: d['urgencyLevel'] ?? 'standard',
      hospitalName: d['hospitalName'] ?? '',
      location: d['location'] ?? '', adminId: d['adminId'] ?? '',
      status: d['status'] ?? 'open',
      respondedDonors: List<String>.from(d['respondedDonors'] ?? []),
      confirmedDonors: List<String>.from(d['confirmedDonors'] ?? []),
      completedDonors: List<String>.from(d['completedDonors'] ?? []),
      notes: d['notes'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requiredBy: (d['requiredBy'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'bloodType': bloodType, 'unitsNeeded': unitsNeeded,
    'urgencyLevel': urgencyLevel, 'hospitalName': hospitalName,
    'location': location, 'adminId': adminId, 'status': status,
    'respondedDonors': respondedDonors, 'confirmedDonors': confirmedDonors,
    'completedDonors': completedDonors, 'notes': notes, 'createdAt': Timestamp.fromDate(createdAt),
    'requiredBy': requiredBy != null ? Timestamp.fromDate(requiredBy!) : null,
  };

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'critical': return const Color(0xFFD84315);
      case 'urgent': return const Color(0xFFF57C00);
      default: return const Color(0xFF1565C0);
    }
  }
}

class AppointmentModel {
  final String id;
  final DateTime date;
  final String timeSlot;
  final String location;
  final int maxCapacity;
  final List<String> bookedDonors;
  final List<String> completedDonors;
  final String adminId;
  final String status;

  const AppointmentModel({
    required this.id, required this.date, required this.timeSlot,
    required this.location, required this.maxCapacity,
    required this.bookedDonors, this.completedDonors = const [],
    required this.adminId, required this.status,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: d['timeSlot'] ?? '', location: d['location'] ?? '',
      maxCapacity: d['maxCapacity'] ?? 10,
      bookedDonors: List<String>.from(d['bookedDonors'] ?? []),
      completedDonors: List<String>.from(d['completedDonors'] ?? []),
      adminId: d['adminId'] ?? '', status: d['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date), 'timeSlot': timeSlot,
    'location': location, 'maxCapacity': maxCapacity,
    'bookedDonors': bookedDonors, 'completedDonors': completedDonors,
    'adminId': adminId, 'status': status,
  };

  int get availableSlots => maxCapacity - bookedDonors.length;
  bool get isFull => availableSlots <= 0;
}

class BloodInventoryModel {
  final String id;
  final String bloodType;
  final int units;
  final DateTime collectedAt;
  final DateTime expiresAt;
  final String status;

  const BloodInventoryModel({
    required this.id, required this.bloodType, required this.units,
    required this.collectedAt, required this.expiresAt, required this.status,
  });

  factory BloodInventoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BloodInventoryModel(
      id: doc.id, bloodType: d['bloodType'] ?? '', units: d['units'] ?? 0,
      collectedAt: (d['collectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() => {
    'bloodType': bloodType, 'units': units,
    'collectedAt': Timestamp.fromDate(collectedAt),
    'expiresAt': Timestamp.fromDate(expiresAt), 'status': status,
  };

  bool get isExpiringSoon => expiresAt.difference(DateTime.now()).inDays <= 7;
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;
}

class DonationHistoryModel {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodType;
  final DateTime donationDate;
  final String location;
  final String healthStatus;
  final String status;
  final String? appointmentId;
  final String? requestId;

  const DonationHistoryModel({
    required this.id, required this.donorId, required this.donorName,
    required this.bloodType, required this.donationDate,
    required this.location, required this.healthStatus,
    required this.status, this.appointmentId, this.requestId,
  });

  factory DonationHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DonationHistoryModel(
      id: doc.id, donorId: d['donorId'] ?? '',
      donorName: d['donorName'] ?? '', bloodType: d['bloodType'] ?? '',
      donationDate: (d['donationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] ?? '', healthStatus: d['healthStatus'] ?? 'healthy',
      status: d['status'] ?? 'donated',
      appointmentId: d['appointmentId'], requestId: d['requestId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'donorId': donorId, 'donorName': donorName, 'bloodType': bloodType,
    'donationDate': Timestamp.fromDate(donationDate), 'location': location,
    'healthStatus': healthStatus, 'status': status,
    'appointmentId': appointmentId, 'requestId': requestId,
  };
}

class EligibilityModel {
  final String donorId;
  final DateTime? lastDonationDate;
  final DateTime? nextEligibleDate;
  final String lastHealthStatus;
  final bool isPermanentlyIneligible;
  final bool isEligible;

  const EligibilityModel({
    required this.donorId, this.lastDonationDate, this.nextEligibleDate,
    required this.lastHealthStatus, required this.isPermanentlyIneligible,
    required this.isEligible,
  });

  factory EligibilityModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final nextDate = (d['nextEligibleDate'] as Timestamp?)?.toDate();
    return EligibilityModel(
      donorId: doc.id,
      lastDonationDate: (d['lastDonationDate'] as Timestamp?)?.toDate(),
      nextEligibleDate: nextDate,
      lastHealthStatus: d['lastHealthStatus'] ?? 'healthy',
      isPermanentlyIneligible: d['isPermanentlyIneligible'] ?? false,
      isEligible: nextDate == null || nextDate.isBefore(DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() => {
    'donorId': donorId,
    'lastDonationDate': lastDonationDate != null ? Timestamp.fromDate(lastDonationDate!) : null,
    'nextEligibleDate': nextEligibleDate != null ? Timestamp.fromDate(nextEligibleDate!) : null,
    'lastHealthStatus': lastHealthStatus,
    'isPermanentlyIneligible': isPermanentlyIneligible,
  };
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id, required this.content, required this.isUser,
    required this.timestamp, this.isLoading = false,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id, required this.title, required this.body,
    required this.type, required this.data, required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id, title: d['title'] ?? '', body: d['body'] ?? '',
      type: d['type'] ?? 'general',
      data: Map<String, dynamic>.from(d['data'] ?? {}),
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'body': body, 'type': type, 'data': data,
    'isRead': isRead, 'createdAt': Timestamp.fromDate(createdAt),
  };
}
