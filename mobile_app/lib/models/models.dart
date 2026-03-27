import 'package:flutter/material.dart';

class ActivityItem {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String time;

  const ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.time,
  });
}

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

class Tenant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String roomNumber;
  final String floor;
  final String bed;
  final double rent;
  final String status;
  final String avatarInitials;
  final int avatarColor;
  final String? gender;
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;
  final int? dueDay;

  const Tenant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roomNumber,
    required this.floor,
    required this.bed,
    required this.rent,
    required this.status,
    required this.avatarInitials,
    required this.avatarColor,
    this.gender,
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
    this.dueDay,
  });
}

class RoomOption {
  final int id;
  final String room_no;
  final String floor;
  final String bed;
  final int capacity;
  final int current_occupancy;
  final String status;
  final int availableBeds;

  const RoomOption({
    required this.id,
    required this.room_no,
    required this.floor,
    required this.bed,
    required this.capacity,
    required this.current_occupancy,
    required this.status,
    required this.availableBeds,
  });
}

class RentRecord {
  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantInitials;
  final int tenantAvatarColor;
  final String roomNumber;
  final double amount;
  final double totalRent;
  final String paymentMode; // 'Cash', 'UPI', 'Bank'
  final DateTime paymentDate;
  final DateTime dueDate;
  final String status; // 'Paid', 'Due', 'Overdue', 'Partially Paid'
  final String? note;

  RentRecord({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantInitials,
    required this.tenantAvatarColor,
    required this.roomNumber,
    required this.amount,
    required this.totalRent,
    required this.paymentMode,
    required this.paymentDate,
    required this.dueDate,
    required this.status,
    this.note,
  });

  RentRecord copyWith({
    String? status,
    double? amount,
    String? paymentMode,
    DateTime? paymentDate,
    String? note,
  }) {
    return RentRecord(
      id: id,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantInitials: tenantInitials,
      tenantAvatarColor: tenantAvatarColor,
      roomNumber: roomNumber,
      amount: amount ?? this.amount,
      totalRent: totalRent,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

class RentActivity {
  final String id;
  final String tenantName;
  final String tenantInitials;
  final int tenantAvatarColor;
  final String roomNumber;
  final double amount;
  final String paymentMode;
  final DateTime dateTime;
  final String type; // 'paid', 'overdue', 'due'

  RentActivity({
    required this.id,
    required this.tenantName,
    required this.tenantInitials,
    required this.tenantAvatarColor,
    required this.roomNumber,
    required this.amount,
    required this.paymentMode,
    required this.dateTime,
    required this.type,
  });
}


class MaintenanceRequest {
  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantInitials;
  final int tenantAvatarColor;
  final String roomNumber;
  final String issueTitle;
  final String description;
  final String category;
  final String priority; // 'High', 'Medium', 'Low'
  final String status;   // 'Pending', 'In Progress', 'Overdue', 'Resolved'
  final DateTime dateRaised;
  final String? adminResponse;
  final String? imageUrl;
  final DateTime? dueDate;
  final DateTime? resolvedAt;

  MaintenanceRequest({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantInitials,
    required this.tenantAvatarColor,
    required this.roomNumber,
    required this.issueTitle,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.dateRaised,
    this.adminResponse,
    this.imageUrl,
    this.dueDate,
    this.resolvedAt,
  });

  MaintenanceRequest copyWith({String? status, String? adminResponse, DateTime? dueDate}) {
    return MaintenanceRequest(
      id: id,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantInitials: tenantInitials,
      tenantAvatarColor: tenantAvatarColor,
      roomNumber: roomNumber,
      issueTitle: issueTitle,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      dueDate: dueDate ?? this.dueDate,
      dateRaised: dateRaised,
    );
  }
}