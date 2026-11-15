import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local contribution and dispute preview state.
class PaymentHubState {
  /// Creates the payment state.
  const PaymentHubState({
    this.contribution = 'Outstanding',
    this.disputeOpen = false,
  });

  /// Current contribution status.
  final String contribution;

  /// Whether a dispute is awaiting review.
  final bool disputeOpen;
}

/// Coordinates local contribution and dispute actions.
class PaymentHubController extends StateNotifier<PaymentHubState> {
  /// Creates the payment controller.
  PaymentHubController() : super(const PaymentHubState());

  /// Records a captain-reported payment.
  void reportPaid() => state = PaymentHubState(
    contribution: 'Captain-reported',
    disputeOpen: state.disputeOpen,
  );

  /// Opens a contribution dispute.
  void dispute() => state = const PaymentHubState(
    contribution: 'Disputed',
    disputeOpen: true,
  );

  /// Resolves the dispute as unpaid.
  void resolveUnpaid() =>
      state = const PaymentHubState(contribution: 'Resolved unpaid');

  /// Shows the refunded contribution state.
  void refund() => state = PaymentHubState(
    contribution: 'Refunded',
    disputeOpen: state.disputeOpen,
  );
}

/// Owns the payment screen's preview state.
final paymentHubControllerProvider =
    StateNotifierProvider.autoDispose<PaymentHubController, PaymentHubState>(
      (ref) => PaymentHubController(),
    );
