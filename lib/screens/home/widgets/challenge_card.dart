import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat =
        DateFormat('MMM d', context.locale.toLanguageTag());

    Color statusColor;
    String statusText;
    switch (challenge.status) {
      case ChallengeStatus.pending:
        statusColor = Colors.orange;
        statusText = 'status_pending'.tr();
      case ChallengeStatus.active:
        statusColor = colorScheme.primary;
        statusText = 'status_active'.tr();
      case ChallengeStatus.completed:
        statusColor = Colors.green;
        statusText = 'status_completed'.tr();
      case ChallengeStatus.failed:
        statusColor = colorScheme.error;
        statusText = 'status_failed'.tr();
      case ChallengeStatus.cancelled:
        statusColor = colorScheme.outline;
        statusText = 'status_cancelled'.tr();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'at_stake'.tr(args: [challenge.stakeAmountDollars.toStringAsFixed(0)]),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(challenge.startDate)} — ${dateFormat.format(challenge.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(Icons.person, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    challenge.arbiterName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (challenge.isActive) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'days_completed'.tr(args: ['${challenge.completedDays}']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
