import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';
import '../../../models/day_record.dart';

class DayGrid extends StatelessWidget {
  final List<DayRecord> records;
  final void Function(DayRecord record) onDayTap;

  const DayGrid({
    super.key,
    required this.records,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dayFormat = DateFormat('d', context.locale.toLanguageTag());
        final isToday = _isToday(record.date);

        Color bgColor;
        IconData? icon;
        switch (record.status) {
          case DayStatus.approved:
            bgColor = Colors.green;
            icon = Icons.check;
          case DayStatus.rejected:
            bgColor = record.canResubmit ? Colors.orange : colorScheme.error;
            icon = record.canResubmit ? Icons.refresh : Icons.close;
          case DayStatus.missed:
            bgColor = colorScheme.error;
            icon = Icons.close;
          case DayStatus.proofSubmitted:
            bgColor = Colors.blue;
            icon = Icons.hourglass_top;
          case DayStatus.pending:
            bgColor = isToday
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest;
            icon = null;
        }

        return GestureDetector(
          onTap: () => onDayTap(record),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayFormat.format(record.date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: record.status == DayStatus.pending
                        ? colorScheme.onSurface
                        : Colors.white,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    size: 14,
                    color: Colors.white,
                  ),
                if (record.status == DayStatus.rejected && record.proofAttempts > 0)
                  Text(
                    '${record.proofAttempts}/${AppConstants.maxProofAttempts}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
