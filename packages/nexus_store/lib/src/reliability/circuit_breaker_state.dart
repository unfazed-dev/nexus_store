/// Represents the state of a circuit breaker.
///
/// Circuit breakers prevent cascade failures by temporarily blocking requests
/// to a failing service:
/// - [closed]: Normal operation, requests flow through
/// - [open]: Requests are blocked (fail fast)
/// - [halfOpen]: Testing if service has recovered
///
/// ## State Transitions
///
/// ```
/// [closed] --failures >= threshold--> [open]
/// [open] --cooldown elapsed--> [halfOpen]
/// [halfOpen] --success >= threshold--> [closed]
/// [halfOpen] --any failure--> [open]
/// ```
///
/// ## Example
///
/// ```dart
/// void handleState(CircuitBreakerState state) {
///   if (!state.allowsRequests) {
///     throw CircuitBreakerOpenException();
///   }
///   if (state.isHalfOpen) {
///     // Limit concurrent requests during recovery
///   }
/// }
/// ```
enum CircuitBreakerState {
  /// Closed state - normal operation.
  ///
  /// All requests are allowed through. Failures are counted and if they
  /// exceed the threshold, the circuit breaker transitions to [open].
  closed,

  /// Open state - blocking requests.
  ///
  /// All requests fail immediately without attempting the operation.
  /// After the cooldown period, transitions to [halfOpen].
  open,

  /// Half-open state - testing recovery.
  ///
  /// Limited requests are allowed through to test if the service has
  /// recovered. Successes transition to [closed], failures to [open].
  halfOpen;

  /// Returns `true` if requests should be allowed through.
  ///
  /// Only [open] state blocks requests; both [closed] and [halfOpen]
  /// allow requests (though [halfOpen] may limit them).
  bool get allowsRequests => this != open;

  /// Returns `true` if this is the closed (normal) state.
  bool get isClosed => this == closed;

  /// Returns `true` if this is the open (blocking) state.
  bool get isOpen => this == open;

  /// Returns `true` if this is the half-open (testing) state.
  bool get isHalfOpen => this == halfOpen;

  /// Returns `true` if this state is at least as severe as [other].
  ///
  /// Severity order: closed (0) < open (1) < halfOpen (2)
  ///
  /// Useful for threshold comparisons:
  /// ```dart
  /// if (state.isAtLeast(CircuitBreakerState.open)) {
  ///   showDegradedMessage();
  /// }
  /// ```
  bool isAtLeast(CircuitBreakerState other) => index >= other.index;
}
