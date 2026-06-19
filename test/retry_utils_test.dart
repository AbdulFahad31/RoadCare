import 'package:flutter_test/flutter_test.dart';
import 'package:road_care/core/utils/retry_utils.dart';

void main() {
  group('RetryUtils Tests', () {
    test('succeeds on the first attempt', () async {
      int calls = 0;
      final result = await RetryUtils.retry(
        operationName: 'testSuccess',
        operation: () async {
          calls++;
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: Duration.zero,
      );

      expect(result, 'success');
      expect(calls, 1);
    });

    test('retries on failure and eventually succeeds', () async {
      int calls = 0;
      final result = await RetryUtils.retry(
        operationName: 'testEventuallySucceeds',
        operation: () async {
          calls++;
          if (calls < 3) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        maxAttempts: 4,
        initialDelay: Duration.zero,
      );

      expect(result, 'success');
      expect(calls, 3);
    });

    test('fails permanently after max attempts', () async {
      int calls = 0;
      expect(
        () => RetryUtils.retry(
          operationName: 'testPermanentFailure',
          operation: () async {
            calls++;
            throw Exception('Failure');
          },
          maxAttempts: 3,
          initialDelay: Duration.zero,
        ),
        throwsException,
      );
      // Wait a small bit to ensure all futures complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(calls, 3);
    });
  });
}
