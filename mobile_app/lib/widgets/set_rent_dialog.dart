import 'package:flutter/material.dart';

class SetRentDialog extends StatefulWidget {
  final Function(Map<String, double> rents) onSave;

  const SetRentDialog({super.key, required this.onSave});

  @override
  State<SetRentDialog> createState() => _SetRentDialogState();
}

class _SetRentDialogState extends State<SetRentDialog> {
  final _singleCtrl = TextEditingController();
  final _doubleCtrl = TextEditingController();
  final _tripleCtrl = TextEditingController();

  @override
  void dispose() {
    _singleCtrl.dispose();
    _doubleCtrl.dispose();
    _tripleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_singleCtrl.text.isEmpty ||
        _doubleCtrl.text.isEmpty ||
        _tripleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all rent fields'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }

    widget.onSave({
      'Single': double.tryParse(_singleCtrl.text) ?? 0,
      'Double': double.tryParse(_doubleCtrl.text) ?? 0,
      'Triple': double.tryParse(_tripleCtrl.text) ?? 0,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Rent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close,
                        color: Color(0xFF9E9E9E), size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Set monthly rent per bed type for your PG',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 20),
            _rentField('Single Room', _singleCtrl, context),
            const SizedBox(height: 12),
            _rentField('Double Room', _doubleCtrl, context),
            const SizedBox(height: 12),
            _rentField('Triple Room', _tripleCtrl, context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  child: GestureDetector(
                    onTap: _submit,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Save Rent',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rentField(String label, TextEditingController ctrl, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.currency_rupee,
                  color: Color(0xFF9E9E9E), size: 18),
            ),
          ),
        ),
      ],
    );
  }
}