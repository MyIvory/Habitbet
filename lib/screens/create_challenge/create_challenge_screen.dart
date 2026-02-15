import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../models/app_user.dart';
import '../../models/challenge.dart';
import '../../models/day_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
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

  int _durationDays = 21;
  int _requiredDaysPerWeek = 7;
  String _selectedCharityId = AppConstants.charities.first.id;
  bool _isLoading = false;

  AppUser? _selectedArbiter;
  bool _isSearchingArbiter = false;
  String? _arbiterSearchError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stakeController.dispose();
    _arbiterEmailController.dispose();
    super.dispose();
  }

  Future<void> _searchArbiterByEmail() async {
    final email = _arbiterEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    final firebaseUser = ref.read(authStateProvider).value;
    if (firebaseUser != null && email.toLowerCase() == firebaseUser.email?.toLowerCase()) {
      setState(() {
        _arbiterSearchError = 'cannot_be_own_arbiter'.tr();
        _selectedArbiter = null;
      });
      return;
    }

    setState(() {
      _isSearchingArbiter = true;
      _arbiterSearchError = null;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await firestoreService.findUserByEmail(email);
      if (mounted) {
        setState(() {
          _selectedArbiter = user;
          _isSearchingArbiter = false;
          _arbiterSearchError =
              user == null ? 'no_user_found'.tr() : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingArbiter = false;
          _arbiterSearchError = 'search_failed'.tr(args: ['$e']);
        });
      }
    }
  }

  void _selectPreviousArbiter(AppUser arbiter) {
    setState(() {
      _selectedArbiter = arbiter;
      _arbiterEmailController.text = arbiter.email;
      _arbiterSearchError = null;
    });
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedArbiter == null) {
      setState(() => _arbiterSearchError = 'please_select_arbiter'.tr());
      return;
    }

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

      final challenge = Challenge(
        id: challengeId,
        creatorId: firebaseUser.uid,
        creatorName: currentUser?.displayName ?? firebaseUser.displayName ?? '',
        arbiterId: _selectedArbiter!.uid,
        arbiterName: _selectedArbiter!.displayName,
        arbiterEmail: _selectedArbiter!.email,
        arbiterStatus: ArbiterStatus.pending,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        stakeAmountCents: stakeAmount,
        charityId: _selectedCharityId,
        charityName: charity.name,
        durationDays: _durationDays,
        requiredDaysPerWeek: _requiredDaysPerWeek,
        startDate: startDate,
        endDate: endDate,
        status: ChallengeStatus.pending,
        createdAt: now,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createChallenge(challenge);

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
          SnackBar(content: Text('challenge_created'.tr())),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_create'.tr(args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousArbitersAsync = ref.watch(previousArbitersProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('new_challenge'.tr()),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                label: 'challenge_title_label'.tr(),
                hint: 'challenge_title_hint'.tr(),
                controller: _titleController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'title_required'.tr() : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'description_label'.tr(),
                hint: 'description_hint'.tr(),
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'stake_amount_label'.tr(),
                hint: '25.00',
                controller: _stakeController,
                prefixText: '\$ ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'stake_required'.tr();
                  final amount = double.tryParse(v);
                  if (amount == null) return 'invalid_amount'.tr();
                  if (amount < AppConstants.minStakeCents / 100) {
                    return 'min_stake'.tr(args: ['${(AppConstants.minStakeCents / 100).toStringAsFixed(0)}']);
                  }
                  if (amount > AppConstants.maxStakeCents / 100) {
                    return 'max_stake'.tr(args: ['${(AppConstants.maxStakeCents / 100).toStringAsFixed(0)}']);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'duration_days'.tr(args: ['$_durationDays']),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _durationDays.toDouble(),
                min: AppConstants.minChallengeDays.toDouble(),
                max: AppConstants.maxChallengeDays.toDouble(),
                divisions:
                    AppConstants.maxChallengeDays - AppConstants.minChallengeDays,
                label: '$_durationDays',
                onChanged: (v) =>
                    setState(() => _durationDays = v.round()),
              ),
              const SizedBox(height: 16),
              Text(
                'required_days_per_week'.tr(args: ['$_requiredDaysPerWeek']),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _requiredDaysPerWeek.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_requiredDaysPerWeek',
                onChanged: (v) =>
                    setState(() => _requiredDaysPerWeek = v.round()),
              ),
              const SizedBox(height: 24),
              Text(
                'charity_label'.tr(),
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
                          child: Text(c.name.tr()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCharityId = v);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'arbiter_label'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),

              // Previous arbiters
              previousArbitersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (arbiters) {
                  if (arbiters.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'previous_arbiters'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: arbiters.map((arbiter) {
                          final isSelected =
                              _selectedArbiter?.uid == arbiter.uid;
                          return ActionChip(
                            avatar: isSelected
                                ? const Icon(Icons.check, size: 18)
                                : const Icon(Icons.person, size: 18),
                            label: Text(arbiter.displayName),
                            backgroundColor: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            onPressed: () => _selectPreviousArbiter(arbiter),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'or_search_by_email'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),

              // Email search field
              AppTextField(
                label: 'arbiter_email_label'.tr(),
                hint: 'arbiter_email_hint'.tr(),
                controller: _arbiterEmailController,
                keyboardType: TextInputType.emailAddress,
                suffixIcon: _isSearchingArbiter
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchArbiterByEmail,
                      ),
                validator: (v) {
                  if (_selectedArbiter != null) return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'arbiter_email_required'.tr();
                  }
                  if (!v.contains('@')) return 'invalid_email'.tr();
                  return null;
                },
              ),

              if (_arbiterSearchError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _arbiterSearchError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],

              // Selected arbiter display
              if (_selectedArbiter != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _selectedArbiter!.photoUrl.isNotEmpty
                          ? NetworkImage(_selectedArbiter!.photoUrl)
                          : null,
                      child: _selectedArbiter!.photoUrl.isEmpty
                          ? Text(_selectedArbiter!.displayName.isNotEmpty
                              ? _selectedArbiter!.displayName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(_selectedArbiter!.displayName),
                    subtitle: Text(_selectedArbiter!.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedArbiter = null;
                          _arbiterEmailController.clear();
                        });
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              AppButton(
                label: 'create_challenge_pay'.tr(),
                icon: Icons.rocket_launch,
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
