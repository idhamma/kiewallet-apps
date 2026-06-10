import 'package:flutter/material.dart';
import '../../utils/date_utils.dart';

class DateRange {
  final String start;
  final String end;
  const DateRange(this.start, this.end);
  DateRange copy({String? start, String? end}) =>
      DateRange(start ?? this.start, end ?? this.end);
}

class GlobalDateFilter extends StatelessWidget {
  final DateRange value;
  final ValueChanged<DateRange> onChanged;

  const GlobalDateFilter({super.key, required this.value, required this.onChanged});

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(value.start),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(value.copy(start: _iso(picked)));
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(value.end),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(value.copy(end: _iso(picked)));
  }

  String _matchPreset() {
    if (value.start == getToday() && value.end == getToday()) return 'today';
    if (value.start == getStartOfWeek() && value.end == getEndOfWeek()) return 'week';
    if (value.start == getStartOfMonth() && value.end == getEndOfMonth()) return 'month';
    if (value.start == getStartOfYear() && value.end == getEndOfYear()) return 'year';
    return 'custom';
  }

  Widget _dateChip(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(text,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 12,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const Icon(Icons.calendar_today, size: 16),
        const Text('Rentang:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        _dateChip(value.start, () => _pickStart(context)),
        const Text('-', style: TextStyle(fontWeight: FontWeight.w900)),
        _dateChip(value.end, () => _pickEnd(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButton<String>(
            value: _matchPreset(),
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            items: const [
              DropdownMenuItem(value: 'custom', child: Text('Pilih Rentang...')),
              DropdownMenuItem(value: 'today', child: Text('Hari Ini')),
              DropdownMenuItem(value: 'week', child: Text('Minggu Ini')),
              DropdownMenuItem(value: 'month', child: Text('Bulan Ini')),
              DropdownMenuItem(value: 'year', child: Text('Tahun Ini')),
            ],
            onChanged: (val) {
              switch (val) {
                case 'today':
                  onChanged(DateRange(getToday(), getToday()));
                  break;
                case 'week':
                  onChanged(DateRange(getStartOfWeek(), getEndOfWeek()));
                  break;
                case 'month':
                  onChanged(DateRange(getStartOfMonth(), getEndOfMonth()));
                  break;
                case 'year':
                  onChanged(DateRange(getStartOfYear(), getEndOfYear()));
                  break;
              }
            },
          ),
        ),
      ],
    );
  }
}
