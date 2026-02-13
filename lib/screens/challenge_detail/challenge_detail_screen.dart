import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/day_record.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/user_provider.dart';
import 'widgets/day_grid.dart';
import 'widgets/proof_bottom_sheet.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(challengeId));
    final dayRecordsAsync = ref.watch(dayRecordsProvider(challengeId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(text: 'Check out my HabitBet challenge!'),
              );
            },
          ),
        ],
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (challenge) {
          if (challenge == null) {
            return const Center(child: Text('Challenge not found'));
          }

          final dateFormat = DateFormat('MMM d, yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  challenge.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (challenge.description.isNotEmpty) ...[
                  Text(
                    challenge.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Stake',
                        value:
                            '\$${challenge.stakeAmountDollars.toStringAsFixed(0)}',
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Duration',
                        value: '${challenge.durationDays} days',
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Frequency',
                        value: '${challenge.requiredDaysPerWeek}x/week',
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info rows
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Period',
                  value:
                      '${dateFormat.format(challenge.startDate)} — ${dateFormat.format(challenge.endDate)}',
                ),
                _InfoRow(
                  icon: Icons.person,
                  label: 'Arbiter',
                  value: challenge.arbiterName,
                ),
                _InfoRow(
                  icon: Icons.favorite,
                  label: 'Charity',
                  value: challenge.charityName,
                ),
                const SizedBox(height: 16),

                // Progress
                Text(
                  'Progress',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 12,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.completedDays} completed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${challenge.missedDays} missed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Day grid
                Text(
                  'Daily Log',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                dayRecordsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading days: $e'),
                  data: (records) => DayGrid(
                    records: records,
                    onDayTap: (record) =>
                        _onDayTap(context, ref, record),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onDayTap(BuildContext context, WidgetRef ref, DayRecord record) {
    if (!record.needsProof) {
      // Show status info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: ${record.status.name}')),
      );
      return;
    }

    // Check if it's today or past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate =
        DateTime(record.date.year, record.date.month, record.date.day);

    if (recordDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can\'t submit proof for future days')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProofBottomSheet(
        record: record,
        onSubmit: (imageUrl, note) {
          final firestoreService = ref.read(firestoreServiceProvider);
          firestoreService.updateDayRecord(
            record.challengeId,
            record.id,
            {
              'status': DayStatus.proofSubmitted.name,
              'proofImageUrl': imageUrl,
              'proofNote': note,
              'submittedAt': DateTime.now().toIso8601String(),
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
