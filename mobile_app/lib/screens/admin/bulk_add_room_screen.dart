import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BulkAddRoomScreen extends StatefulWidget {
  final String token;
  final List<String> existingFloors;
  final VoidCallback onSaved;

  const BulkAddRoomScreen({
    required this.token,
    required this.existingFloors,
    required this.onSaved,
  });

  @override
  State<BulkAddRoomScreen> createState() => _BulkAddRoomScreenState();
}

class _BulkAddRoomScreenState extends State<BulkAddRoomScreen> {
  List<String> _floors = [];
  final _newFloorCtrl = TextEditingController();
  String? _selectedFloor;
  bool _isSaving = false;

  // List of rooms to add
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _floors = List.from(widget.existingFloors);
    if (_floors.isNotEmpty) _selectedFloor = _floors[0];
    _addNewRoomRow();
  }

  void _addNewRoomRow() {
    setState(() {
      _rooms.add({
        'roomNoCtrl': TextEditingController(),
        'rentCtrl': TextEditingController(),
        'sharing': 1,
      });
    });
  }

  void _removeRoomRow(int index) {
    setState(() => _rooms.removeAt(index));
  }

  void _addFloor() {
    final name = _newFloorCtrl.text.trim();
    if (name.isEmpty) return;
    if (_floors.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floor already exists!')),
      );
      return;
    }
    setState(() {
      _floors.add(name);
      _selectedFloor ??= name;
      _newFloorCtrl.clear();
    });
  }

  Future<void> _saveAll() async {
    if (_selectedFloor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a floor!')),
      );
      return;
    }

    for (final room in _rooms) {
      if ((room['roomNoCtrl'] as TextEditingController).text.trim().isEmpty ||
          (room['rentCtrl'] as TextEditingController).text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all room details!')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      for (final room in _rooms) {
        final sharing = room['sharing'] as int;
        print('RENT: ${(room['rentCtrl'] as TextEditingController).text.trim()}');
        print('PARSED: ${double.tryParse((room['rentCtrl'] as TextEditingController).text.trim())}');
        await ApiService.addRoom(
          widget.token,
          (room['roomNoCtrl'] as TextEditingController).text.trim(),
          _selectedFloor!,
          '$sharing Sharing',
          sharing,
          double.tryParse(
                  (room['rentCtrl'] as TextEditingController).text.trim()) ??
              0,
        );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_rooms.length} rooms added successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving rooms!')),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
        title: Text('Add Rooms',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Step 1: Floors ──
            _sectionTitle('Step 1 — Manage Floors'),
            const SizedBox(height: 12),

            // Existing floors
            if (_floors.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _floors.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedFloor == f
                        ? const Color(0xFF2196F3)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedFloor == f
                          ? const Color(0xFF2196F3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFloor = f),
                    child: Text(f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedFloor == f
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        )),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 12),

            // Add new floor
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _newFloorCtrl,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        hintText: 'New floor name e.g. Floor 1',
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addFloor,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('+ Add',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ── Step 2: Rooms ──
            _sectionTitle('Step 2 — Add Rooms for $_selectedFloor'),
            const SizedBox(height: 12),

            // Room rows
            ..._rooms.asMap().entries.map((entry) {
              final i = entry.key;
              final room = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Room ${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3))),
                        if (_rooms.length > 1)
                          GestureDetector(
                            onTap: () => _removeRoomRow(i),
                            child: const Icon(Icons.close,
                                color: Colors.red, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Room number
                    _inputField('Room Number',
                        room['roomNoCtrl'] as TextEditingController,
                        hint: 'e.g. G-101'),
                    const SizedBox(height: 10),

                    // Sharing type stepper
                    Row(
                      children: [
                        Text('Sharing Type:',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if ((room['sharing'] as int) > 1) {
                              setState(() => room['sharing'] =
                                  (room['sharing'] as int) - 1);
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                color: Color(0xFF2196F3), size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${room['sharing']} Sharing',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => room['sharing'] =
                              (room['sharing'] as int) + 1),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Color(0xFF2196F3), size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rent
                    _inputField('Rent Amount (₹)',
                        room['rentCtrl'] as TextEditingController,
                        hint: 'e.g. 5000',
                        keyboard: TextInputType.number),
                  ],
                ),
              );
            }),

            // Add another room button
            GestureDetector(
              onTap: _addNewRoomRow,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFF2196F3), size: 18),
                    SizedBox(width: 8),
                    Text('Add Another Room',
                        style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save All button
            GestureDetector(
              onTap: _isSaving ? null : _saveAll,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Save All ${_rooms.length} Room${_rooms.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface));
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {String hint = '', TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}