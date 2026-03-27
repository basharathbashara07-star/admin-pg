import 'package:flutter/material.dart';
import '../models/models.dart';

class MaintenanceDetailSheet extends StatefulWidget {
  final MaintenanceRequest request;
  final Function(MaintenanceRequest updated) onStatusUpdate;
  final Function(String id) onDelete;

  const MaintenanceDetailSheet({
    super.key,
    required this.request,
    required this.onStatusUpdate,
    required this.onDelete,
  });

  @override
  State<MaintenanceDetailSheet> createState() =>
      _MaintenanceDetailSheetState();
}

class _MaintenanceDetailSheetState extends State<MaintenanceDetailSheet> {
  late String _selectedStatus;
  final _responseController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
    _responseController.text = widget.request.adminResponse ?? '';
  }

  String _formatDate(DateTime d) {
    const months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':   return const Color(0xFFF44336);
      case 'Medium': return const Color(0xFFFF9800);
      case 'Low':    return const Color(0xFF4CAF50);
      default:       return const Color(0xFF9E9E9E);
    }
  }

  Color _priorityBg(String p) {
    switch (p) {
      case 'High':   return const Color(0xFFFFEBEE);
      case 'Medium': return const Color(0xFFFFF3E0);
      case 'Low':    return const Color(0xFFE8F5E9);
      default:       return const Color(0xFFEEEEEE);
    }
  }

  @override
  void dispose() {
  _responseController.dispose();
  super.dispose();
 }
  
  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

 void _updateStatus() {
    final updated = widget.request.copyWith(
      status: _selectedStatus,
      adminResponse: _responseController.text,
      dueDate: _selectedDueDate,
    );
    widget.onStatusUpdate(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Complaint Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _priorityBg(widget.request.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔴 ${widget.request.priority}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _priorityColor(widget.request.priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFF9E9E9E), size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tenant Info Strip ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          Color(widget.request.tenantAvatarColor),
                      child: Text(
                        widget.request.tenantInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.tenantName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Room ${widget.request.roomNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.request.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Issue Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.request.issueTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      widget.request.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A1A2E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Date + Category + Resolved row ──
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Raised',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 4),
            Text(_formatDate(widget.request.dateRaised),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 4),
            Text(widget.request.category,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
      if (widget.request.status == 'Resolved' && widget.request.resolvedAt != null)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resolved On',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 4),
              Text(_formatDate(widget.request.resolvedAt!),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
            ],
          ),
        ),
    ],
  ),
),
const SizedBox(height: 24),

            // ---- Admin Response
            if (widget.request.status != 'Resolved') ...[
            const SizedBox(height: 16),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Admin Response (Optional)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _responseController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your response here...',
            hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ),
    ],
  ),
),

 const SizedBox(height: 16),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Due Date',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickDueDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2196F3)),
              const SizedBox(width: 10),
              Text(
                _selectedDueDate == null
                    ? 'Tap to set due date'
                    : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDueDate == null ? const Color(0xFFBDBDBD) : const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
            ],
            // ── Update Status ──
            if (widget.request.status != 'Resolved') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statusOption('Pending',     const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
                      const SizedBox(width: 8),
                      _statusOption('In Progress', const Color(0xFF00BCD4), const Color(0xFFE0F7FA)),
                      const SizedBox(width: 8),
                      _statusOption('Resolved',    const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ],
                 
               // ── Delete Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(widget.request.id);
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Delete Complaint',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Save Button ──
            if (widget.request.status != 'Resolved') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _updateStatus,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1A2E).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(String status, Color color, Color bgColor) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}