enum BroActionType { cab_booking, food_order, shopping, payment, query, none }

enum BroStatus { success, pending, failed }

class BroResponse {

  BroResponse({
    required this.actionType,
    required this.status,
    required this.text,
    required this.executionTime, this.data,
    this.error,
  });

  factory BroResponse.failed(String error) => BroResponse(
        actionType: BroActionType.none,
        status: BroStatus.failed,
        text: 'Sorry boss, kuch phat gaya. $error',
        executionTime: 0,
        error: error,
      );
  final BroActionType actionType;
  final BroStatus status;
  final String text; // The verbal response from BRO
  final dynamic data; // Detailed data for the action (e.g. cab details)
  final double executionTime;
  final String? error;
}
