/// ──────────────────────────────────────────────────────────────────────────────
/// Date Range Selector – Reusable UI Component
/// ──────────────────────────────────────────────────────────────────────────────
/// A horizontal chip row that lets the user pick between Today, Last 7 Days,
/// or a custom date range.  When "Custom Range" is selected, a date‑range
/// picker is shown.
/// ──────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/date_range_option.dart';

class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onCustomRange,
    this.customStart,
    this.customEnd,
  });

  final DateRangeOption selected;
  final ValueChanged<DateRangeOption> onSelected;
  final void Function(DateTime start, DateTime end) onCustomRange;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: DateRangeOption.values.map((option) {
              final isSelected = option == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => _handleChipTap(context, option),
                ),
              );
            }).toList(),
          ),
        ),

        // Show the custom range label when active.
        if (selected == DateRangeOption.custom && customStart != null && customEnd != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '${DateFormat.yMMMd().format(customStart!)} – '
              '${DateFormat.yMMMd().format(customEnd!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<void> _handleChipTap(BuildContext context, DateRangeOption option) async {
    if (option == DateRangeOption.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: customStart ?? now.subtract(const Duration(days: 7)),
          end: customEnd ?? now,
        ),
      );
      if (picked != null) {
        // Ensure the end covers the full day.
        final endOfDay = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        onCustomRange(picked.start, endOfDay);
      }
    } else {
      onSelected(option);
    }
  }
}
