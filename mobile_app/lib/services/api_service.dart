import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.6:5000';

  // Login function (existing)
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed');
    }
  }

  // ✅ Tenant Forgot Password API
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/tenant/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  // ✅ Admin Forgot Password API
  static Future<Map<String, dynamic>> adminForgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/admin/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  // ✅ Verify OTP API call (tenant)
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/tenant/verify-otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'OTP verification failed');
    }
  }

  // ✅ Tenant Reset Password API (kept unchanged)
  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/tenant/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'new_password': newPassword}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Password reset failed');
    }
  }

  // ✅ Admin Verify OTP API
  static Future<Map<String, dynamic>> verifyAdminOtp(
      String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/admin/verify-otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Admin OTP verification failed');
    }
  }

  // ✅ NEW: Admin Reset Password API
  static Future<Map<String, dynamic>> adminResetPassword(
      String email, String newPassword) async {

    final url = Uri.parse('$baseUrl/api/admin/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'new_password': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Admin password reset failed');
    }
  }
  // ✅ Admin Register API
  static Future<Map<String, dynamic>> registerAdmin(
    String registerNo,
    String name,
    String email,
    String phone,
    String password,
    String pgName,
    String address,
    String city,
  ) async {

    final url = Uri.parse('$baseUrl/api/admin/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'register_no': registerNo,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'pg_name': pgName,
        'address': address,
        'city': city,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      return {
        "success": false,
        "message": data['message'] ?? "Registration failed"
      };
    }
  }


             //    ✅ Fetch Tenants
static Future<Map<String, dynamic>> fetchTenants(String token) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch tenants');
  }
}

// ✅ Fetch Rooms
static Future<Map<String, dynamic>> fetchRooms(String token) async {
  final url = Uri.parse('$baseUrl/api/admin/rooms');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch rooms');
  }
}
// ✅ Fetch Rent by bed type
static Future<Map<String, dynamic>> fetchRent(String token, String bedType) async {
  final url = Uri.parse('$baseUrl/api/admin/rent/$bedType');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch rent');
  }
}


// ✅ Add Tenant
static Future<Map<String, dynamic>> addTenant(
  String token,
  String name,
  String email,
  String phone,
  String gender,
  String fatherName,
  String fatherPhone,
  String motherName,
  String motherPhone,
  int roomId,
  String bedType,
  int dueDay,
) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'father_name': fatherName,
      'father_phone': fatherPhone,
      'mother_name': motherName,
      'mother_phone': motherPhone,
      'room_id': roomId,
      'bed_type': bedType,
      'due_day' : dueDay,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to add tenant');
  }
}

                                                           // ✅ Record Payment
static Future<Map<String, dynamic>> recordPayment(
  String token,
  int tenantId,
  double amount,
  double totalRent,
  String paymentMode,
  String month,
  String dueDate,
  String paymentDate,
) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/payment');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'tenant_id': tenantId,
      'amount': amount,
      'total_rent': totalRent,
      'payment_mode': paymentMode,
      'month': month,
      'due_date': dueDate,
      'payment_date': paymentDate,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to record payment');
  }
}


// ✅ Update Tenant
static Future<Map<String, dynamic>> updateTenant(
  String token,
  String tenantId,
  String email,
  String phone,
  String fatherName,
  String fatherPhone,
  String motherName,
  String motherPhone,
  int? roomId,
) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/$tenantId');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'email': email,
      'phone': phone,
      'father_name': fatherName,
      'father_phone': fatherPhone,
      'mother_name': motherName,
      'mother_phone': motherPhone,
      if (roomId != null) 'room_id': roomId,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to update tenant');
  }
}
                   

                               // ✅ Vacate Tenant
static Future<Map<String, dynamic>> vacateTenant(
  String token,
  String tenantId,
) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/$tenantId/vacate');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to vacate tenant');
  }
}
        
 // ✅ Delete Tenant
static Future<Map<String, dynamic>> deleteTenant(
  String token,
  String tenantId,
) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/$tenantId');

  final response = await http.delete(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to delete tenant');
  }
}


// ✅ Fetch Single Tenant
static Future<Map<String, dynamic>> fetchTenant(String token, String tenantId) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/$tenantId');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch tenant');
  }
}
   // ✅ Fetch Tenant Counts
static Future<Map<String, dynamic>> fetchTenantCounts(String token) async {
  final url = Uri.parse('$baseUrl/api/admin/tenants/counts');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    return {'total': 0, 'active': 0, 'vacated': 0, 'pending': 0};
  }
}

// ✅ Fetch Rent Summary
static Future<Map<String, dynamic>> fetchRentSummary(String token) async {
  final url = Uri.parse('$baseUrl/api/admin/rent/summary');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch rent summary');
  }
}

//calendar fetch
static Future<Map<String, dynamic>> fetchTenantsStatus(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/rent/tenants-status'),
    headers: {'Authorization': 'Bearer $token'},
  );
  return jsonDecode(response.body);
}
 //OVERDUE
static Future<Map<String, dynamic>> fetchOverdueMonths(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/rent/overdue-months'),
    headers: {'Authorization': 'Bearer $token'},
  );
  return jsonDecode(response.body);
}

  //All PAYMENTS
  static Future<Map<String, dynamic>> fetchTenantPayments(String token, String tenantId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/tenants/$tenantId/payments'),
    headers: {'Authorization': 'Bearer $token'},
  );
  return jsonDecode(response.body);
}

// ✅ Fetch Complaints
static Future<List<dynamic>> fetchComplaints(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/complaints'),
    headers: {'Authorization': 'Bearer $token'},
  );
  return jsonDecode(response.body);
}

// ✅ Update Complaint Status
static Future<void> updateComplaintStatus(String token, String id, String status, {String? adminResponse, DateTime? dueDate}) async {
  await http.put(
    Uri.parse('$baseUrl/api/admin/complaints/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'status': status,
      'admin_response': adminResponse ?? '',
      'due_date': dueDate != null ? '${dueDate.year}-${dueDate.month.toString().padLeft(2,'0')}-${dueDate.day.toString().padLeft(2,'0')}' : null,
    }),
  );
}

  // ✅ Delete Complaint
static Future<void> deleteComplaint(String token, String id) async {
  await http.delete(
    Uri.parse('$baseUrl/api/admin/complaints/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
}  

// ✅ Fetch Dashboard Summary
static Future<Map<String, dynamic>> fetchDashboardSummary(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/dashboard/summary'),
    headers: {'Authorization': 'Bearer $token'},
  );
  return jsonDecode(response.body);
}

}