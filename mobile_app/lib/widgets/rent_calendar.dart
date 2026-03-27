import 'package:flutter/material.dart';
import '../models/models.dart';

class RentCalendar extends StatefulWidget {
  final List<RentRecord> records;
  final Function(DateTime date, List<RentRecord> records) onDateSelected;

  const RentCalendar({
    super.key,
    required this.records,
    required this.onDateSelected,
  });

  @override
  State<RentCalendar> createState() => _RentCalendarState();
}

class _RentCalendarState extends State<RentCalendar> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  // ── Get all days that have activity ──
  Map<int, String> get _dayTypes {
    final Map<int, String> types = {};
    for (final r in widget.records) {
      // Paid records — mark payment date
      if (r.status == 'Paid') {
        final d = r.paymentDate;
        if (d.year == _currentMonth.year && d.month == _currentMonth.month) {
          types[d.day] = 'paid';
        }
      }
      // Due/Overdue — mark due date
      if (r.status == 'Due' || r.status == 'Overdue' || r.status == 'Partially Paid') {
        final d = r.dueDate;
        if (d.year == _currentMonth.year && d.month == _currentMonth.month) {
          types[d.day] = types[d.day] == 'paid' ? 'both' : 'due';
        }
      }
    }
    return types;
  }

  int get _daysInMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  int get _firstWeekday =>
      DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDate = null;
    });
  }

  void _onDayTap(int day) {
    final tapped = DateTime(_currentMonth.year, _currentMonth.month, day);
    setState(() => _selectedDate = tapped);
    
    // Filter records for this date
    final filtered = widget.records.where((r) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tappedDay = DateTime(tapped.year, tapped.month, tapped.day);
      final isPastOrToday = !tappedDay.isAfter(today);

      if (isPastOrToday) {
        // Show payments made ON this date
        return _isSameDay(r.paymentDate, tapped);
      } else {
        // Show tenants DUE on this date
        return _isSameDay(r.dueDate, tapped);
      }
    }).toList();
    print('Filtered count: ${filtered.length}');
    widget.onDateSelected(tapped, filtered);
  }


  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == _currentMonth.year &&
        now.month == _currentMonth.month &&
        now.day == day;
  }

  bool _isSelected(int day) =>
      _selectedDate != null &&
      _selectedDate!.year == _currentMonth.year &&
      _selectedDate!.month == _currentMonth.month &&
      _selectedDate!.day == day;

  @override
  Widget build(BuildContext context) {
    final dayTypes = _dayTypes;
    const dayHeaders = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1432),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Month Navigation ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E44),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Color(0xFF8090C8), size: 20),
                  ),
                ),
                Text(
                  '${months[_currentMonth.month - 1]}  ${_currentMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E44),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Color(0xFF8090C8), size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Container(height: 1, color: const Color(0xFF161E44)),

          // ── Day Headers ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayHeaders.map((d) => SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: d == 'Su'
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF6478BE),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          // ── Date Grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: _firstWeekday + _daysInMonth,
              itemBuilder: (context, index) {
                if (index < _firstWeekday) return const SizedBox();
                final day = index - _firstWeekday + 1;
                final isSel    = _isSelected(day);
                final isToday  = _isToday(day);
                final isSun    = (index % 7) == 0;
                final dotType  = dayTypes[day];

                return GestureDetector(
                  onTap: () => _onDayTap(day),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel
                              ? const Color(0xFF2196F3)
                              : isToday
                                  ? const Color(0xFF1E2855)
                                  : Colors.transparent,
                          border: isToday && !isSel
                              ? Border.all(
                                  color: const Color(0xFF2196F3), width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSel
                                  ? Colors.white
                                  : isToday
                                      ? const Color(0xFF2196F3)
                                      : isSun
                                          ? const Color(0xFFEF5350)
                                          : const Color(0xFFC8D2F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // ── Dot indicator ──
                      if (dotType != null && !isSel)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (dotType == 'paid' || dotType == 'both')
                              _dot(const Color(0xFF4CAF50)),
                            if (dotType == 'both')
                              const SizedBox(width: 2),
                            if (dotType == 'due' || dotType == 'both')
                              _dot(const Color(0xFFFF9800)),
                          ],
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Legend ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _legendItem(const Color(0xFF4CAF50), 'Paid'),
                const SizedBox(width: 16),
                _legendItem(const Color(0xFFFF9800), 'Due'),
                const SizedBox(width: 16),
                _legendItem(const Color(0xFF2196F3), 'Today', isRing: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _legendItem(Color color, String label, {bool isRing = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRing ? Colors.transparent : color,
            border: isRing ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8090C8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}