import 'package:flutter_test/flutter_test.dart';
import 'package:rs2_desktop/core/api/api_client.dart';
import 'package:rs2_desktop/core/services/api/misc_api_services.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';

class FakeProcurementApiService extends ProcurementApiService {
  FakeProcurementApiService({required this.checkoutSessionResponse});

  final ApiResponse<String> checkoutSessionResponse;

  @override
  Future<ApiResponse<String>> createCheckoutSession(
    String procurementOrderId,
  ) async {
    return checkoutSessionResponse;
  }
}

void main() {
  test('initiatePayment returns checkout url on success', () async {
    final provider = ProcurementProvider(
      apiService: FakeProcurementApiService(
        checkoutSessionResponse: ApiResponse.success(
          'https://checkout.stripe.com/test-url',
        ),
      ),
    );

    final result = await provider.initiatePayment('order-1');

    expect(result.success, isTrue);
    expect(result.checkoutUrl, 'https://checkout.stripe.com/test-url');
    expect(provider.error, isNull);
  });

  test('initiatePayment maps technical error to user-safe message', () async {
    final provider = ProcurementProvider(
      apiService: FakeProcurementApiService(
        checkoutSessionResponse: ApiResponse.failure(
          'Cannot connect to backend. Please check Docker and localhost port.',
        ),
      ),
    );

    final result = await provider.initiatePayment('order-2');

    expect(result.success, isFalse);
    expect(result.checkoutUrl, isNull);
    expect(
      result.userMessage,
      'Cannot reach the server right now. Please try again.',
    );
    expect(provider.error, result.userMessage);
    expect(result.userMessage.toLowerCase(), isNot(contains('docker')));
  });
}
