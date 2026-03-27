import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:table_calendar/table_calendar.dart';

class AddTenantDialog extends StatefulWidget {
  final List<RoomOption> vacantRooms;
  final Function(String name, String email, String phone, RoomOption room,String gender,
      String fatherName,  String fatherPhone,  String motherName,String motherPhone,double rent, int dueDay) onAdd;

  const AddTenantDialog({
    super.key,
    required this.vacantRooms,
    required this.onAdd,
  });

  @override
  State<AddTenantDialog> createState() => _AddTenantDialogState();
}

class _AddTenantDialogState extends State<AddTenantDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  RoomOption? _selectedRoom;
  double? _fetchedRent;
  bool _loadingRent = false;
  DateTime? _moveInDate;
  bool _isSubmitting = false;
  String? _selectedGender;
  int _dueDay = 5;

  @override
  void initState() {
  super.initState();
  _nameCtrl.addListener(() => setState(() => _errorMessage = null));
  _emailCtrl.addListener(() => setState(() => _errorMessage = null));
  _phoneCtrl.addListener(() => setState(() => _errorMessage = null));
}

  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherPhoneCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRent(String bedType) async {
    setState(() => _loadingRent = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.fetchRent(token, bedType);
      if (data['success'] == true) {
        setState(() {
          _fetchedRent = double.tryParse(data['amount'].toString());
          _loadingRent = false;
        });
      }
    } catch (e) {
      setState(() => _loadingRent = false);
    }
  }
      
  Future<void> _pickDate() async {
  await showDialog(
    context: context,
    builder: (context) {
      DateTime focusedDay = DateTime.now();
      DateTime? selectedDay = _moveInDate;

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setStateCalendar) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Text('Select Move-In Date',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calendar
                  TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) =>
                        selectedDay != null &&
                        day.year == selectedDay!.year &&
                        day.month == selectedDay!.month &&
                        day.day == selectedDay!.day,
                    onDaySelected: (selected, focused) {
                      setStateCalendar(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold),
                      weekendTextStyle:
                          const TextStyle(color: Color(0xFFF44336)),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                      leftChevronIcon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF2196F3)),
                      rightChevronIcon: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF2196F3)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF44336)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Button
                  GestureDetector(
                    onTap: () {
                      if (selectedDay != null) {
                        setState(() => _moveInDate = selectedDay);
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Confirm Date',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  String _ordinal(int n) {
  if (n >= 11 && n <= 13) return 'th';
  switch (n % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}

String? _errorMessage;
void _showError(String message) {
  setState(() => _errorMessage = message);
}

  Future<void> _submit() async {
    // Validate all fields
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter tenant full name');
      return;
    }

   if (_selectedGender == null) {
  _showError('Please select gender');
  return;
}
    
    if (_emailCtrl.text.trim().isEmpty) {
      _showError('Please enter email address');
      return;
    }
    if (!_validateEmail(_emailCtrl.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Please enter phone number');
      return;
    }
    if (!_validatePhone(_phoneCtrl.text.trim())) {
      _showError('Phone number must be exactly 10 digits');
      return;
    }
    if (_fatherNameCtrl.text.trim().isEmpty) {
      _showError('Please enter father\'s name');
      return;
    }
    if (_fatherPhoneCtrl.text.trim().isEmpty) {
      _showError('Please enter father\'s phone number');
      return;
    }
    if (!_validatePhone(_fatherPhoneCtrl.text.trim())) {
      _showError('Father\'s phone must be exactly 10 digits');
      return;
    }
    if (_motherNameCtrl.text.trim().isEmpty) {
      _showError('Please enter mother\'s name');
      return;
    }
    if (_motherPhoneCtrl.text.trim().isEmpty) {
      _showError('Please enter mother\'s phone number');
      return;
    }
    if (!_validatePhone(_motherPhoneCtrl.text.trim())) {
      _showError('Mother\'s phone must be exactly 10 digits');
      return;
    }
    if (_selectedRoom == null) {
      _showError('Please select a room');
      return;
    }
    if (_moveInDate == null) {
      _showError('Please select move-in date');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final emergencyContact =
          'Father: ${_fatherNameCtrl.text.trim()} (${_fatherPhoneCtrl.text.trim()}) | Mother: ${_motherNameCtrl.text.trim()} (${_motherPhoneCtrl.text.trim()})';

      final data = await ApiService.addTenant(
        token,
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _selectedGender!,
        _fatherNameCtrl.text.trim(),
        _fatherPhoneCtrl.text.trim(),
        _motherNameCtrl.text.trim(),
        _motherPhoneCtrl.text.trim(),
        _selectedRoom!.id,
        _selectedRoom!.bed,
        _dueDay,
      );

      if (data['success'] == true) {
        widget.onAdd(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _phoneCtrl.text.trim(),
          _selectedRoom!,
          _selectedGender!,
          _fatherNameCtrl.text.trim(),
          _fatherPhoneCtrl.text.trim(),
          _motherNameCtrl.text.trim(),
          _motherPhoneCtrl.text.trim(),
          _fetchedRent ?? 0,
          _dueDay,
        );
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('${_nameCtrl.text.trim()} added!Login credentials sent to email'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
          Navigator.pop(context);
      } else {
        _showError(data['message'] ?? 'Failed to add tenant');
      }
    } catch (e) {
      _showError('Error: $e');
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Tenant',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Assign room & manage tenant details',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
                                                                             // ── Scrollable Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tenant Details Section ──
                    _sectionCard(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF2196F3),
                      iconBg: const Color(0xFFE3F2FD),
                      borderColor: const Color(0xFF2196F3),
                      title: 'Tenant Details',
                      child: Column(
                        children: [
                          _formRow('Full Name', 'Enter full name',
                              _nameCtrl, Icons.badge_outlined),
                          const SizedBox(height: 12),
                          // Gender Dropdown
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Gender',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7))),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        dropdownColor: Theme.of(context).cardColor,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          prefixIcon: Icon(Icons.person_outline_rounded,
              color: Color(0xFF9E9E9E), size: 18),
        ),
        hint: Text('Select gender',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4))),
        items: ['Male', 'Female', 'Other'].map((g) {
          return DropdownMenuItem(
            value: g,
            child: Text(g,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface)),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedGender = val),
      ),
    ),
  ],
),
const SizedBox(height: 12),
                          _formRow('Email Address', 'example@gmail.com',
                              _emailCtrl, Icons.email_outlined,
                              keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _formRow('Phone Number', 'Enter mobile number',
                              _phoneCtrl, Icons.phone_rounded,
                              keyboard: TextInputType.phone,
                              maxLength: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Emergency Contact Section ──
                    _sectionCard(
                      icon: Icons.emergency_rounded,
                      iconColor: const Color(0xFFFF6F00),
                      iconBg: const Color(0xFFFFF3E0),
                      borderColor: const Color(0xFFFF6F00),
                      title: 'Emergency Contact',
                      subtitle: '⚠️ Both father & mother details are required',
                      subtitleColor: const Color(0xFFFF6F00),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Father
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          const Color(0xFFE3F2FD),
                                      child: const Icon(Icons.man_rounded,
                                          color: Color(0xFF1565C0),
                                          size: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Father Details',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _miniField('Father Name',
                                    'Enter father\'s name', _fatherNameCtrl,
                                    Icons.badge_outlined),
                                const SizedBox(height: 8),
                                _miniField('Father Phone',
                                    'Enter father\'s phone', _fatherPhoneCtrl,
                                    Icons.phone_rounded,
                                    keyboard: TextInputType.phone,
                                    maxLength: 10),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Mother
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          const Color(0xFFFCE4EC),
                                      child: const Icon(Icons.woman_rounded,
                                          color: Color(0xFF880E4F),
                                          size: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Mother Details',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF880E4F))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _miniField('Mother Name',
                                    'Enter mother\'s name', _motherNameCtrl,
                                    Icons.badge_outlined),
                                const SizedBox(height: 8),
                                _miniField('Mother Phone',
                                    'Enter mother\'s phone', _motherPhoneCtrl,
                                    Icons.phone_rounded,
                                    keyboard: TextInputType.phone,
                                    maxLength: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),


                                                                           // ── Due Day Section ──
_sectionCard(
  icon: Icons.calendar_today_rounded,
  iconColor: const Color(0xFF9C27B0),
  iconBg: const Color(0xFFF3E5F5),
  borderColor: const Color(0xFF9C27B0),
  title: 'Rent Due Day',
  child: Column(
    children: [
      Text(
        'Rent is due every month on',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minus button
          GestureDetector(
            onTap: () {
              if (_dueDay > 1) setState(() => _dueDay--);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
              ),
              child: const Icon(Icons.remove_rounded, color: Color(0xFF9C27B0)),
            ),
          ),
          const SizedBox(width: 20),
          // Day display
          Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$_dueDay',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Plus button
          GestureDetector(
            onTap: () {
              if (_dueDay < 28) setState(() => _dueDay++);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        '${_dueDay}${_ordinal(_dueDay)} of every month',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9C27B0),
        ),
      ),
    ],
  ),
),
                       
            // ── Room Assignment Section ──
                    _sectionCard(
                      icon: Icons.meeting_room_rounded,
                      iconColor: const Color(0xFF00897B),
                      iconBg: const Color(0xFFE0F2F1),
                      borderColor: const Color(0xFF00897B),
                      title: 'Room Assignment',
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0)),
                            ),
                            child: DropdownButtonFormField<RoomOption>(
                              value: _selectedRoom,
                              dropdownColor: Theme.of(context).cardColor,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                prefixIcon: Icon(
                                    Icons.door_front_door_outlined,
                                    color: Color(0xFF9E9E9E),
                                    size: 18),
                              ),
                              hint: Text('Choose a room',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4),
                                      fontSize: 13)),
                              items: widget.vacantRooms.map((room) {
                                return DropdownMenuItem(
                                  value: room,
                                  child: Text(
                                    '${room.room_no} · ${room.floor} · ${room.bed}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRoom = val;
                                  _fetchedRent = null;
                                });
                                if (val != null) _fetchRent(val.bed);
                              },
                            ),
                          ),

                          // Room Details Card
                          if (_selectedRoom != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF00897B)
                                          .withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.door_front_door_rounded,
                                            color: Color(0xFF00897B),
                                            size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Room No: ${_selectedRoom!.room_no}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00897B)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _roomDetail(
                                            Icons.people_rounded,
                                            'Sharing: ${_selectedRoom!.bed}',
                                            const Color(0xFF00897B)),
                                        const SizedBox(width: 12),
                                        _roomDetail(
                                            Icons.bed_rounded,
                                            'Available: ${_selectedRoom!.availableBeds}',
                                            const Color(0xFF00897B)),
                                        const SizedBox(width: 12),
                                        if (_loadingRent)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF00897B)),
                                          )
                                        else if (_fetchedRent != null)
                                          _roomDetail(
                                              Icons.currency_rupee_rounded,
                                              '₹${_fetchedRent!.toStringAsFixed(0)}',
                                              const Color(0xFF00897B)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                                                                   // ── Move-In Details Section ──
                    _sectionCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF7B1FA2),
                      iconBg: const Color(0xFFF3E5F5),
                      borderColor: const Color(0xFF7B1FA2),
                      title: 'Move-In Details',
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Color(0xFF7B1FA2), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _moveInDate == null
                                    ? 'Select Move-In Date'
                                    : '${_moveInDate!.day}/${_moveInDate!.month}/${_moveInDate!.year}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _moveInDate == null
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down_rounded,
                                  color: Color(0xFF9E9E9E)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                                 
                   // ── Error Message ──
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF44336).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFF44336), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF44336),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _errorMessage = null),
                              child: const Icon(Icons.close,
                                  color: Color(0xFFF44336), size: 16),
                            ),
                          ],
                        ),
                      ),





                    // ── Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: const Center(
                                child: Text('Cancel',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9E9E9E))),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _isSubmitting ? null : _submit,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF7B1FA2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_add_rounded,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Add Tenant',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color borderColor,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor ?? const Color(0xFF9E9E9E))),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _formRow(String label, String hint, TextEditingController ctrl,
      IconData icon,
      {TextInputType keyboard = TextInputType.text, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            inputFormatters: maxLength != null
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength)
                  ]
                : null,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              prefixIcon:
                  Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
            ),
          ),
        ),
      ],
    );
  }
  Widget _miniField(String label, String hint, TextEditingController ctrl,
      IconData icon,
      {TextInputType keyboard = TextInputType.text, int? maxLength}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: maxLength != null
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLength)
              ]
            : null,
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.35)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          prefixIcon:
              Icon(icon, color: const Color(0xFF9E9E9E), size: 16),
        ),
      ),
    );
  }

  Widget _roomDetail(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}