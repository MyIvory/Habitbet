class AppConstants {
  AppConstants._();

  // Firebase — configure in firebase console
  static const firebaseProjectId = 'habitbet-app-2026-f6e4c';

  // Stripe — configure in Stripe dashboard
  static const stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
  static const stripeMerchantId = 'merchant.com.habitbet';

  // Minimum / maximum stake amounts (in USD cents)
  static const minStakeCents = 500; // $5
  static const maxStakeCents = 50000; // $500

  // Challenge duration limits
  static const minChallengeDays = 7;
  static const maxChallengeDays = 90;

  // Proof submission deadline (hours from midnight)
  static const proofDeadlineHour = 23;
  static const proofDeadlineMinute = 59;

  // Reminder time
  static const reminderHour = 20;
  static const reminderMinute = 0;

  // Charities list
  static const charities = [
    Charity(id: 'red_cross', name: 'Red Cross', logoUrl: ''),
    Charity(id: 'unicef', name: 'UNICEF', logoUrl: ''),
    Charity(id: 'wwf', name: 'WWF', logoUrl: ''),
    Charity(id: 'doctors_without_borders', name: 'Doctors Without Borders', logoUrl: ''),
  ];

  // Privacy policy
  static const privacyPolicyUrl = 'https://habitbet.app/privacy';
  static const termsUrl = 'https://habitbet.app/terms';
}

class Charity {
  final String id;
  final String name;
  final String logoUrl;

  const Charity({
    required this.id,
    required this.name,
    required this.logoUrl,
  });
}
