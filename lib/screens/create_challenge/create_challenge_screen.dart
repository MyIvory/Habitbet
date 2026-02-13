import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../models/challenge.dart';
import '../../models/day_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stakeController = TextEditingController();
  final _arbiterEmailController = TextEditingController();
  final _arbiterNameController = TextEditingController();

  int _durationDays = 21;
  int _requiredDaysPerWeek = 7;
  String _selectedCharityId = AppConstants.charities.first.id;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stakeController.dispose();
    _arbiterEmailController.dispose();
    _arbiterNameController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseUser = ref.read(authStateProvider).value;
      if (firebaseUser == null) throw Exception('Not authenticated');

      final currentUser = ref.read(currentUserProvider).value;
      final stakeAmount =
          (double.parse(_stakeController.text) * 100).round();
      final charity = AppConstants.charities
          .firstWhere((c) => c.id == _selectedCharityId);

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day + 1);
      final endDate = startDate.add(Duration(days: _durationDays));

      const uuid = Uuid();
      final challengeId = uuid.v4();

      // Mock payment intent (Stripe disabled)
      final paymentIntentId = 'pi_mock_$challengeId';

      final challenge = Challenge(
        id: challengeId,
        creatorId: firebaseUser.uid,
        creatorName: currentUser?.displayName ?? firebaseUser.displayName ?? '',
        arbiterId: '', // Will be resolved when arbiter accepts
        arbiterName: _arbiterNameController.text.trim(),
        arbiterEmail: _arbiterEmailController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        stakeAmountCents: stakeAmount,
        charityId: _selectedCharityId,
        charityName: charity.name,
        durationDays: _durationDays,
        requiredDaysPerWeek: _requiredDaysPerWeek,
        startDate: startDate,
        endDate: endDate,
        status: ChallengeStatus.active,
        stripePaymentIntentId: paymentIntentId,
        createdAt: now,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createChallenge(challenge);

      // Create day records for the entire duration
      for (var i = 0; i < _durationDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dayRecord = DayRecord(
          id: uuid.v4(),
          challengeId: challengeId,
          date: date,
        );
        await firestoreService.createDayRecord(dayRecord);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challenge: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Challenge'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                label: 'Challenge Title',
                hint: 'e.g., Run every morning',
                controller: _titleController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'What exactly do you commit to?',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Stake Amount',
                hint: '25.00',
                controller: _stakeController,
                prefixText: '\$ ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Stake is required';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid amount';
                  if (amount < AppConstants.minStakeCents / 100) {
                    return 'Minimum stake is \$${(AppConstants.minStakeCents / 100).toStringAsFixed(0)}';
                  }
                  if (amount > AppConstants.maxStakeCents / 100) {
                    return 'Maximum stake is \$${(AppConstants.maxStakeCents / 100).toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Duration: $_durationDays days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _durationDays.toDouble(),
                min: AppConstants.minChallengeDays.toDouble(),
                max: AppConstants.maxChallengeDays.toDouble(),
                divisions:
                    AppConstants.maxChallengeDays - AppConstants.minChallengeDays,
                label: '$_durationDays days',
                onChanged: (v) =>
                    setState(() => _durationDays = v.round()),
              ),
              const SizedBox(height: 16),
              Text(
                'Required days per week: $_requiredDaysPerWeek',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _requiredDaysPerWeek.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_requiredDaysPerWeek days/week',
                onChanged: (v) =>
                    setState(() => _requiredDaysPerWeek = v.round()),
              ),
              const SizedBox(height: 24),
              Text(
                'Charity (if you fail)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCharityId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.charities
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCharityId = v);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Arbiter',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Arbiter Name',
                hint: 'Your friend\'s name',
                controller: _arbiterNameController,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Arbiter name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Arbiter Email',
                hint: 'friend@email.com',
                controller: _arbiterEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Arbiter email is required';
                  }
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Create Challenge & Pay',
                icon: Icons.lock,
                onPressed: _createChallenge,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
