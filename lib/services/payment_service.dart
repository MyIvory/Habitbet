import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Creates a payment intent via Cloud Function.
  /// Returns the payment intent ID for tracking.
  Future<String> createAndConfirmPayment({
    required int amountCents,
    required String currency,
    required String challengeId,
  }) async {
    final result = await _functions.httpsCallable('createPaymentIntent').call({
      'amount': amountCents,
      'currency': currency,
      'challengeId': challengeId,
    });

    final paymentIntentId = result.data['paymentIntentId'] as String;

    // TODO: When Stripe is configured, present payment sheet here:
    // final clientSecret = result.data['clientSecret'] as String;
    // await Stripe.instance.initPaymentSheet(
    //   paymentSheetParameters: SetupPaymentSheetParameters(
    //     paymentIntentClientSecret: clientSecret,
    //     merchantDisplayName: 'HabitBet',
    //   ),
    // );
    // await Stripe.instance.presentPaymentSheet();

    return paymentIntentId;
  }

  /// Capture a held payment (called when challenge fails)
  Future<void> capturePayment(String paymentIntentId) async {
    await _functions.httpsCallable('capturePayment').call({
      'paymentIntentId': paymentIntentId,
    });
  }

  /// Cancel/release a held payment (called when challenge succeeds)
  Future<void> cancelPayment(String paymentIntentId) async {
    await _functions.httpsCallable('cancelPaymentIntent').call({
      'paymentIntentId': paymentIntentId,
    });
  }
}
