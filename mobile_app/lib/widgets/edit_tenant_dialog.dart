import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class EditTenantDialog extends StatefulWidget {
  final Tenant tenant;
  final List<RoomOption> vacantRooms;
  final Function() onUpdated;

  const EditTenantDialog({
    super.key,
    required this.tenant,
    required this.vacantRooms,
    required this.onUpdated,
  });

  @override
  State<EditTenantDialog> createState() => _EditTenantDialogState();
}

class _EditTenantDialogState extends State<EditTenantDialog> {
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _fatherNameCtrl;
  late TextEditingController _fatherPhoneCtrl;
  late TextEditingController _motherNameCtrl;
  late TextEditingController _motherPhoneCtrl;
  RoomOption? _selectedRoom;
  double? _fetchedRent;
  bool _loadingRent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.tenant.email);
    _phoneCtrl = TextEditingController(text: widget.tenant.phone);
    _fatherNameCtrl = TextEditingController(text: widget.tenant.fatherName ?? '');
    _fatherPhoneCtrl = TextEditingController(text: widget.tenant.fatherPhone ?? '');
    _motherNameCtrl = TextEditingController(text: widget.tenant.motherName ?? '');
    _motherPhoneCtrl = TextEditingController(text: widget.tenant.motherPhone ?? '');
  }

  @override
  void dispose() {
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }
    if (_fatherNameCtrl.text.isEmpty || _fatherPhoneCtrl.text.isEmpty) {
      _showError('Please fill father details');
      return;
    }
    if (_motherNameCtrl.text.isEmpty || _motherPhoneCtrl.text.isEmpty) {
      _showError('Please fill mother details');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final data = await ApiService.updateTenant(
        token,
        widget.tenant.id,
        _emailCtrl.text,
        _phoneCtrl.text,
        _fatherNameCtrl.text.trim(),
        _fatherPhoneCtrl.text.trim(),
        _motherNameCtrl.text.trim(),
        _motherPhoneCtrl.text.trim(),
        _selectedRoom?.id,
      );

      if (data['success'] == true) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant updated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Failed to update tenant');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Tenant',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(widget.tenant.name,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Info
                    _sectionCard(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF2196F3),
                      iconBg: const Color(0xFFE3F2FD),
                      borderColor: const Color(0xFF2196F3),
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          _field('Email', _emailCtrl, Icons.email_outlined,
                              keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _field('Phone', _phoneCtrl, Icons.phone_outlined,
                              keyboard: TextInputType.phone, maxLength: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contacts
                    _sectionCard(
                      icon: Icons.emergency_rounded,
                      iconColor: const Color(0xFFFF6F00),
                      iconBg: const Color(0xFFFFF3E0),
                      borderColor: const Color(0xFFFF6F00),
                      title: 'Emergency Contacts',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Father
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFE3F2FD),
                                      child: Icon(Icons.man_rounded,
                                          color: Color(0xFF1565C0), size: 16),
                                    ),
                                    SizedBox(width: 6),
                                    Text('Father',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _miniField('Name', _fatherNameCtrl,
                                    Icons.badge_outlined),
                                const SizedBox(height: 8),
                                _miniField('Phone', _fatherPhoneCtrl,
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
                                  children: const [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFFCE4EC),
                                      child: Icon(Icons.woman_rounded,
                                          color: Color(0xFF880E4F), size: 16),
                                    ),
                                    SizedBox(width: 6),
                                    Text('Mother',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF880E4F))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _miniField('Name', _motherNameCtrl,
                                    Icons.badge_outlined),
                                const SizedBox(height: 8),
                                _miniField('Phone', _motherPhoneCtrl,
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

                    // Room Info
                    _sectionCard(
                      icon: Icons.meeting_room_rounded,
                      iconColor: const Color(0xFF00897B),
                      iconBg: const Color(0xFFE0F2F1),
                      borderColor: const Color(0xFF00897B),
                      title: 'Room Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.door_front_door_rounded,
                                    color: Color(0xFF00897B), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Current: ${widget.tenant.roomNumber} · ${widget.tenant.floor} · ${widget.tenant.bed} · ₹${widget.tenant.rent.toInt()}/month',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF00897B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Change Room (optional)',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9E9E9E))),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE0E0E0)),
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
                              hint: Text('Keep current room',
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
                                    '${room.room_no} · ${room.floor} · ${room.bed} · ${room.availableBeds} left',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedRoom = val);
                                if (val != null) _fetchRent(val.bed);
                              },
                            ),
                          ),
                          if (_loadingRent)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          else if (_fetchedRent != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.currency_rupee_rounded,
                                        color: Color(0xFF00897B), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'New Rent: ₹${_fetchedRent!.toStringAsFixed(0)}/month',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00897B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                                                                // Buttons
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
                            onTap: _submit,
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
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Save Changes',
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
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

  Widget _miniField(String hint, TextEditingController ctrl, IconData icon,
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
            fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
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
}