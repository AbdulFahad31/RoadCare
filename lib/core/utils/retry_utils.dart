import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class RetryUtils {
  /// Executes an operation and retries on failure using exponential backoff with jitter.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    double backoffMultiplier = 2.0,
    bool Function(Exception)? retryIf,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    final random = Random();

    while (true) {
      attempt++;
      try {
        if (kDebugMode && operationName != null && attempt > 1) {
          debugPrint('🔄 [$operationName] Attempt $attempt of $maxAttempts...');
        }
        return await operation();
      } catch (e) {
        final exception = e is Exception ? e : Exception(e.toString());

        final shouldRetry =
            attempt < maxAttempts && (retryIf == null || retryIf(exception));

        if (!shouldRetry) {
          if (kDebugMode && operationName != null) {
            debugPrint(
                '❌ [$operationName] Failed permanently on attempt $attempt: $e');
          }
          rethrow;
        }

        // Apply jitter: randomized factor between 0.8 and 1.2
        final jitterFactor = 0.8 + random.nextDouble() * 0.4;
        final sleepMs = (delay.inMilliseconds * jitterFactor).toInt();
        final sleepDuration = Duration(milliseconds: sleepMs);

        if (kDebugMode && operationName != null) {
          debugPrint(
              '⚠️ [$operationName] Attempt $attempt failed. Retrying in ${sleepDuration.inMilliseconds}ms... Error: $e');
        }

        await Future.delayed(sleepDuration);

        // Update delay for next attempt
        final nextDelayMs = (delay.inMilliseconds * backoffMultiplier).toInt();
        delay =
            Duration(milliseconds: min(nextDelayMs, maxDelay.inMilliseconds));
      }
    }
  }
}
