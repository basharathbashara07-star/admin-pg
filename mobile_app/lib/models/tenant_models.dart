class Tenant {
  final String name;
  final String room;
  final String pgName;
  final String avatar;
  final int rewardPoints;

  Tenant({
    required this.name,
    required this.room,
    required this.pgName,
    required this.avatar,
    required this.rewardPoints,
  });
}

class Payment {
  final String month;
  final double amount;
  final String status; // paid, pending, late
  final DateTime date;

  Payment({
    required this.month,
    required this.amount,
    required this.status,
    required this.date,
  });
}

class MaintenanceTicket {
  final String id;
  final String title;
  final String description;
  final String status; // open, in_progress, resolved
  final DateTime createdAt;
  final String category;

  MaintenanceTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.category,
  });
}

class Expense {
  final String title;
  final double totalAmount;
  final List<String> roommates;
  final Map<String, double> splits;
  final String status;
  final DateTime date;

  Expense({
    required this.title,
    required this.totalAmount,
    required this.roommates,
    required this.splits,
    required this.status,
    required this.date,
  });
}

class Visitor {
  final int id;
  final String name;
  final String phone;
  final String purpose;
  final DateTime visitDate;
  final String status;
  final String? qrToken;
  final DateTime? createdAt;

  Visitor({
    required this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.visitDate,
    required this.status,
    this.qrToken,
    this.createdAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      purpose: json['purpose'],
      visitDate: DateTime.parse(json['visit_date']),
      status: json['status'],
      qrToken: json['qr_code'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'visitor_id': id,
        'name': name,
        'phone': phone,
        'purpose': purpose,
        'visit_date': visitDate.toIso8601String(),
        'status': status,
        'qr_token': qrToken,
        'created_at': createdAt?.toIso8601String(),
      };
}

class Notice {
  final String title;
  final String content;
  final DateTime date;
  final String type; // maintenance, event, payment, general

  Notice({
    required this.title,
    required this.content,
    required this.date,
    required this.type,
  });
}

class ChatMessage {
  final String sender;
  final String message;
  final DateTime time;
  final bool isMe;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.isMe,
  });
}

class TenantBadge {
  final String name;
  final String icon;
  final String description;
  final bool earned;

  TenantBadge({
    required this.name,
    required this.icon,
    required this.description,
    required this.earned,
  });
}