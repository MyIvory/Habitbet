import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/constants.dart';
import '../../models/challenge.dart';
import '../../models/day_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_button.dart';
import 'widgets/day_grid.dart';
import 'widgets/payment_proof_bottom_sheet.dart';
import 'widgets/proof_bottom_sheet.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(challengeId));
    final dayRecordsAsync = ref.watch(dayRecordsProvider(challengeId));
    final authUser = ref.watch(authStateProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('challenge_details'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(text: 'share_challenge'.tr()),
              );
            },
          ),
        ],
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error_generic'.tr(args: ['$e']))),
        data: (challenge) {
          if (challenge == null) {
            return Center(child: Text('challenge_not_found'.tr()));
          }

          final dateFormat =
              DateFormat('MMM d, yyyy', context.locale.toLanguageTag());

          final isCreator = authUser?.uid == challenge.creatorId;

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
                        label: 'stake'.tr(),
                        value:
                            '\$${challenge.stakeAmountDollars.toStringAsFixed(0)}',
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'duration'.tr(),
                        value: 'days_unit'.tr(args: ['${challenge.durationDays}']),
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'frequency'.tr(),
                        value: 'frequency_value'.tr(args: ['${challenge.requiredDaysPerWeek}']),
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info rows
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'period'.tr(),
                  value:
                      '${dateFormat.format(challenge.startDate)} — ${dateFormat.format(challenge.endDate)}',
                ),
                _InfoRow(
                  icon: Icons.person,
                  label: 'arbiter'.tr(),
                  value: challenge.arbiterName,
                ),
                _InfoRow(
                  icon: Icons.favorite,
                  label: 'charity'.tr(),
                  value: challenge.charityName.tr(),
                ),
                const SizedBox(height: 16),

                // Pending banner
                if (challenge.status == ChallengeStatus.pending) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'challenge_pending_hint'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Progress
                Text(
                  'progress'.tr(),
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
                      'completed_count'.tr(args: ['${challenge.completedDays}']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'missed_count'.tr(args: ['${challenge.missedDays}']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (challenge.status == ChallengeStatus.failed) ...[
                  Text(
                    'payment_proof'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _paymentProofStatusText(challenge.paymentProofStatus).tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (challenge.paymentProofRejectionReason != null &&
                      challenge.paymentProofRejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'payment_proof_rejected_reason'.tr(args: [
                        challenge.paymentProofRejectionReason!,
                      ]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                    ),
                  ],
                  if (challenge.arbiterFeedback != null &&
                      challenge.arbiterFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'arbiter_feedback'.tr(args: [challenge.arbiterFeedback!]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (challenge.arbiterRating != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'arbiter_rating_value'
                          .tr(args: ['${challenge.arbiterRating}']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isCreator &&
                      (challenge.paymentProofStatus ==
                              PaymentProofStatus.pending ||
                          challenge.paymentProofStatus ==
                              PaymentProofStatus.rejected)) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'submit_payment_proof'.tr(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => PaymentProofBottomSheet(
                            challengeId: challenge.id,
                            onSubmit: (imageUrl, note) {
                              final firestoreService =
                                  ref.read(firestoreServiceProvider);
                              firestoreService.updateChallenge(challenge.id, {
                                'paymentProofStatus':
                                    PaymentProofStatus.submitted.name,
                                'paymentProofImageUrl': imageUrl,
                                'paymentProofNote': note,
                                'paymentProofSubmittedAt':
                                    DateTime.now().toIso8601String(),
                                'paymentProofRejectionReason': null,
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Day grid
                Text(
                  'daily_log'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                dayRecordsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('error_loading_days'.tr(args: ['$e'])),
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
    // Check challenge status — block if pending
    final challenge = ref.read(challengeDetailProvider(challengeId)).value;
    if (challenge?.status == ChallengeStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('challenge_pending_hint'.tr())),
      );
      return;
    }

    final canSubmit = record.needsProof || record.canResubmit;

    if (!canSubmit) {
      // Show status info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('status_label'.tr(args: [record.status.name]))),
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
        SnackBar(content: Text('no_future_proof'.tr())),
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
              'proofAttempts': record.proofAttempts + 1,
            },
          );
        },
      ),
    );
  }

  String _paymentProofStatusText(PaymentProofStatus status) {
    switch (status) {
      case PaymentProofStatus.pending:
        return 'payment_proof_status_pending';
      case PaymentProofStatus.submitted:
        return 'payment_proof_status_submitted';
      case PaymentProofStatus.approved:
        return 'payment_proof_status_approved';
      case PaymentProofStatus.rejected:
        return 'payment_proof_status_rejected';
      case PaymentProofStatus.none:
        return 'payment_proof_status_none';
    }
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
