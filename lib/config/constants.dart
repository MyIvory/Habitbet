class AppConstants {
  AppConstants._();

  // Firebase — configure in firebase console
  static const firebaseProjectId = 'habitbet-app-2026-f6e4c';

  // Minimum / maximum pledge amounts (in USD cents)
  static const minStakeCents = 500; // $5
  static const maxStakeCents = 50000; // $500

  // Challenge duration limits
  static const minChallengeDays = 7;
  static const maxChallengeDays = 90;

  // Maximum proof submission attempts per day
  static const maxProofAttempts = 3;

  // Proof submission deadline (hours from midnight)
  static const proofDeadlineHour = 23;
  static const proofDeadlineMinute = 59;

  // Reminder time
  static const reminderHour = 20;
  static const reminderMinute = 0;

  // Charities list
  static const charities = [
    Charity(id: 'rusoriz', name: 'charity_rusoriz', logoUrl: ''),
    Charity(id: 'rl', name: 'charity_rl', logoUrl: ''),
    Charity(id: 'arbiter', name: 'charity_arbiter', logoUrl: ''),
  ];

  // Privacy policy
  static const privacyPolicyUrl = 'https://habitbet.app/privacy';
  static const termsUrl = 'https://habitbet.app/terms';
}

class Charity {
  final String id;
  final String name;
  final String logoUrl;

  const Charity({required this.id, required this.name, required this.logoUrl});
}
