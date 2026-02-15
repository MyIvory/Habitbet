import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/challenge.dart';
import '../../models/day_record.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_button.dart';

class ArbitrateScreen extends ConsumerWidget {
  final String challengeId;

  const ArbitrateScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(challengeId));
    final pendingAsync = ref.watch(pendingReviewsProvider(challengeId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('arbitrate'.tr()),
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error_generic'.tr(args: ['$e']))),
        data: (challenge) {
          if (challenge == null) {
            return Center(child: Text('challenge_not_found'.tr()));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge info header
              Container(
                padding: const EdgeInsets.all(16),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by_creator'.tr(args: [challenge.creatorName]),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${challenge.stakeAmountDollars.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              if (challenge.status == ChallengeStatus.failed) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPaymentProofSection(
                    context,
                    ref,
                    challenge,
                  ),
                ),
              ],

              // Pending reviews
              Expanded(
                child: pendingAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('error_generic'.tr(args: ['$e']))),
                  data: (records) {
                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'all_caught_up'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'no_proofs_waiting'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _ProofReviewCard(
                          record: record,
                          onApprove: () =>
                              _approveRecord(ref, record),
                          onReject: () =>
                              _showRejectDialog(context, ref, record),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _approveRecord(WidgetRef ref, DayRecord record) {
    final firestoreService = ref.read(firestoreServiceProvider);
    firestoreService.updateDayRecord(
      record.challengeId,
      record.id,
      {
        'status': DayStatus.approved.name,
        'reviewedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    DayRecord record,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reject_proof'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'rejection_reason_label'.tr(),
            hintText: 'rejection_reason_hint'.tr(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final firestoreService = ref.read(firestoreServiceProvider);
              firestoreService.updateDayRecord(
                record.challengeId,
                record.id,
                {
                  'status': DayStatus.rejected.name,
                  'rejectionReason': reasonController.text.trim(),
                  'reviewedAt': DateTime.now().toIso8601String(),
                },
              );
              Navigator.pop(context);
            },
            child: Text('reject'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofSection(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (challenge.paymentProofStatus) {
      case PaymentProofStatus.pending:
        return _PaymentProofStatusCard(
          icon: Icons.schedule,
          title: 'payment_proof_pending'.tr(),
          subtitle: 'payment_proof_pending_hint'.tr(),
          color: colorScheme.outline,
        );
      case PaymentProofStatus.submitted:
        return _PaymentProofReviewCard(
          imageUrl: challenge.paymentProofImageUrl,
          note: challenge.paymentProofNote,
          onApprove: () => _showApprovePaymentDialog(context, ref, challenge),
          onReject: () => _showRejectPaymentDialog(context, ref, challenge),
        );
      case PaymentProofStatus.approved:
        return _PaymentProofStatusCard(
          icon: Icons.check_circle,
          title: 'payment_proof_approved'.tr(),
          subtitle: 'payment_proof_approved_hint'.tr(),
          color: Colors.green,
        );
      case PaymentProofStatus.rejected:
        return _PaymentProofStatusCard(
          icon: Icons.cancel,
          title: 'payment_proof_rejected'.tr(),
          subtitle: challenge.paymentProofRejectionReason?.isNotEmpty == true
              ? 'payment_proof_rejected_reason'
                  .tr(args: [challenge.paymentProofRejectionReason!])
              : 'payment_proof_rejected_hint'.tr(),
          color: colorScheme.error,
        );
      case PaymentProofStatus.none:
        return _PaymentProofStatusCard(
          icon: Icons.info_outline,
          title: 'payment_proof_none'.tr(),
          subtitle: 'payment_proof_none_hint'.tr(),
          color: colorScheme.outline,
        );
    }
  }

  void _showApprovePaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) {
    int rating = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('approve_payment_proof'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('arbiter_rating_label'.tr(args: ['$rating'])),
              Slider(
                value: rating.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$rating',
                onChanged: (v) => setState(() => rating = v.round()),
              ),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: 'arbiter_feedback_label'.tr(),
                  hintText: 'arbiter_feedback_hint'.tr(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () async {
                await _approvePaymentProof(
                  ref,
                  challenge,
                  rating,
                  feedbackController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('approve'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePaymentProof(
    WidgetRef ref,
    Challenge challenge,
    int rating,
    String feedback,
  ) async {
    final firestoreService = ref.read(firestoreServiceProvider);

    await firestoreService.updateChallenge(challenge.id, {
      'paymentProofStatus': PaymentProofStatus.approved.name,
      'paymentProofReviewedAt': DateTime.now().toIso8601String(),
      'arbiterRating': rating,
      'arbiterFeedback': feedback,
    });

    final creator = await firestoreService.getUser(challenge.creatorId);
    if (creator == null) return;
    await firestoreService.updateUser(challenge.creatorId, {
      'ratingTotal': creator.ratingTotal + rating,
      'ratingCount': creator.ratingCount + 1,
    });
  }

  void _showRejectPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reject_payment_proof'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'rejection_reason_label'.tr(),
            hintText: 'rejection_reason_hint'.tr(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final firestoreService = ref.read(firestoreServiceProvider);
              firestoreService.updateChallenge(challenge.id, {
                'paymentProofStatus': PaymentProofStatus.rejected.name,
                'paymentProofRejectionReason': reasonController.text.trim(),
                'paymentProofReviewedAt': DateTime.now().toIso8601String(),
              });
              Navigator.pop(context);
            },
            child: Text('reject'.tr()),
          ),
        ],
      ),
    );
  }
}

class _PaymentProofReviewCard extends StatelessWidget {
  final String? imageUrl;
  final String? note;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PaymentProofReviewCard({
    required this.imageUrl,
    required this.note,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment_proof_review'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'approve'.tr(),
                    icon: Icons.check,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'reject'.tr(),
                    icon: Icons.close,
                    onPressed: onReject,
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProofStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PaymentProofStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofReviewCard extends StatelessWidget {
  final DayRecord record;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ProofReviewCard({
    required this.record,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        DateFormat('EEEE, MMM d', context.locale.toLanguageTag());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(record.date),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (record.proofImageUrl != null &&
                record.proofImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: record.proofImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),
            if (record.proofNote != null && record.proofNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.proofNote!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'approve'.tr(),
                    icon: Icons.check,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'reject'.tr(),
                    icon: Icons.close,
                    onPressed: onReject,
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
