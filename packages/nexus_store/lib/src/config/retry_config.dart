import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Configuration for retry behavior with exponential backoff.
///
/// ## Example
///
/// ```dart
/// final config = RetryConfig(
///   maxAttempts: 3,
///   initialDelay: Duration(seconds: 1),
///   maxDelay: Duration(seconds: 30),
///   backoffMultiplier: 2.0,
///   jitterFactor: 0.1,
/// );
///
/// // Calculate delay for attempt 2
/// final delay = config.delayForAttempt(2); // ~2 seconds with jitter
/// ```
@immutable
class RetryConfig {
  /// Creates a retry configuration.
  ///
  /// Throws [AssertionError] if:
  /// - [maxAttempts] is less than 1
  /// - [backoffMultiplier] is less than 1.0
  /// - [jitterFactor] is negative or greater than 1.0
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.retryableExceptions = const {},
  })  : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
        assert(
          backoffMultiplier >= 1.0,
          'backoffMultiplier must be at least 1.0',
        ),
        assert(
          jitterFactor >= 0.0 && jitterFactor <= 1.0,
          'jitterFactor must be between 0.0 and 1.0',
        );

  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  ///
  /// Delay for attempt n = initialDelay * (backoffMultiplier ^ (n-1))
  final double backoffMultiplier;

  /// Random jitter factor to prevent thundering herd.
  ///
  /// A value of 0.1 means ±10% randomness applied to each delay.
  final double jitterFactor;

  /// Set of exception types that should trigger retry.
  ///
  /// If empty, all exceptions are retryable.
  final Set<Type> retryableExceptions;

  /// Default configuration with sensible defaults.
  static const RetryConfig defaults = RetryConfig();

  /// Configuration that disables retries.
  static const RetryConfig noRetry = RetryConfig(maxAttempts: 1);

  /// Aggressive retry configuration for critical operations.
  static const RetryConfig aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(minutes: 1),
    backoffMultiplier: 1.5,
    jitterFactor: 0.2,
  );

  /// Calculates the delay before the given attempt number.
  ///
  /// [attempt] is 1-indexed (first retry is attempt 1).
  Duration delayForAttempt(int attempt, {math.Random? random}) {
    assert(attempt >= 1, 'Attempt must be at least 1');

    final baseDelay =
        initialDelay.inMilliseconds * math.pow(backoffMultiplier, attempt - 1);

    final cappedDelay = math.min(baseDelay, maxDelay.inMilliseconds);

    // Apply jitter
    final rand = random ?? math.Random();
    final jitter = 1 + (rand.nextDouble() * 2 - 1) * jitterFactor;
    final finalDelay = (cappedDelay * jitter).round();

    return Duration(milliseconds: finalDelay);
  }

  /// Returns `true` if the given exception should trigger a retry.
  bool shouldRetry(Object exception) {
    if (retryableExceptions.isEmpty) return true;
    return retryableExceptions.contains(exception.runtimeType);
  }

  /// Creates a copy with the specified changes.
  RetryConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    double? jitterFactor,
    Set<Type>? retryableExceptions,
  }) =>
      RetryConfig(
        maxAttempts: maxAttempts ?? this.maxAttempts,
        initialDelay: initialDelay ?? this.initialDelay,
        maxDelay: maxDelay ?? this.maxDelay,
        backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
        jitterFactor: jitterFactor ?? this.jitterFactor,
        retryableExceptions: retryableExceptions ?? this.retryableExceptions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryConfig &&
          runtimeType == other.runtimeType &&
          maxAttempts == other.maxAttempts &&
          initialDelay == other.initialDelay &&
          maxDelay == other.maxDelay &&
          backoffMultiplier == other.backoffMultiplier &&
          jitterFactor == other.jitterFactor;

  @override
  int get hashCode => Object.hash(
        maxAttempts,
        initialDelay,
        maxDelay,
        backoffMultiplier,
        jitterFactor,
      );

  @override
  String toString() => 'RetryConfig('
      'maxAttempts: $maxAttempts, '
      'initialDelay: $initialDelay, '
      'maxDelay: $maxDelay, '
      'backoffMultiplier: $backoffMultiplier, '
      'jitterFactor: $jitterFactor)';
}
