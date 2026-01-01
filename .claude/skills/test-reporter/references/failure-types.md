# Failure Types Reference

test_reporter uses **sealed classes** for type-safe failure classification with exhaustive pattern matching.

## Import

```dart
import 'package:test_reporter/test_reporter.dart';
```

## Base Type

```dart
sealed class FailureType {
  const FailureType();
  String get category;      // Human-readable category name
  String? get suggestion;   // Fix suggestion (nullable)
}
```

---

## Failure Types

### AssertionFailure

Test expectations that failed.

```dart
final class AssertionFailure extends FailureType {
  final String message;
  final String? location;
  final String? expectedValue;
  final String? actualValue;

  String get category => "Assertion Failure";
}
```

**Detection Patterns:**
- `Expected:` / `Actual:`
- `expect()` failures
- `matcher` mismatches

**Example:**
```dart
case AssertionFailure(:final message, :final expectedValue, :final actualValue):
  print('Expected $expectedValue but got $actualValue');
  print('Message: $message');
```

**Common Fixes:**
- Verify expected values are correct
- Check for floating-point comparison issues
- Use appropriate matchers

---

### NullError

Null pointer exceptions.

```dart
final class NullError extends FailureType {
  final String? variableName;
  final String? location;

  String get category => "Null Reference Error";
}
```

**Detection Patterns:**
- `Null check operator used on a null value`
- `NoSuchMethodError: The method '...' was called on null`
- `type 'Null' is not a subtype of type`

**Example:**
```dart
case NullError(:final variableName, :final location):
  print('Null reference on $variableName at $location');
```

**Common Fixes:**
- Add null checks (`?.` or `??`)
- Ensure proper initialization
- Check mock setup returns non-null

---

### TimeoutFailure

Test timeouts.

```dart
final class TimeoutFailure extends FailureType {
  final Duration? duration;
  final String? operation;

  String get category => "Timeout";
}
```

**Detection Patterns:**
- `Test timed out`
- `TimeoutException`
- `Future not completed`

**Example:**
```dart
case TimeoutFailure(:final duration, :final operation):
  print('Operation "$operation" timed out after $duration');
```

**Common Fixes:**
- Increase timeout: `timeout: Duration(seconds: 30)`
- Optimize async operations
- Check for infinite loops or deadlocks
- Ensure Futures complete

---

### RangeError

Index out of bounds errors.

```dart
final class RangeError extends FailureType {
  final int? index;
  final String? validRange;

  String get category => "Range Error";
}
```

**Detection Patterns:**
- `RangeError: index`
- `Index out of range`
- `Invalid value: Not in range`

**Example:**
```dart
case RangeError(:final index, :final validRange):
  print('Index $index is outside valid range $validRange');
```

**Common Fixes:**
- Add bounds checking
- Verify list/array is populated
- Check loop conditions

---

### TypeError

Type casting and mismatch errors.

```dart
final class TypeError extends FailureType {
  final String? expectedType;
  final String? actualType;
  final String? location;

  String get category => "Type Error";
}
```

**Detection Patterns:**
- `type '...' is not a subtype of type '...'`
- `_CastError`
- `TypeError`

**Example:**
```dart
case TypeError(:final expectedType, :final actualType, :final location):
  print('Cannot cast $actualType to $expectedType at $location');
```

**Common Fixes:**
- Use proper type casts (`as`, `is`)
- Check generic type parameters
- Verify JSON deserialization types

---

### IOError

File system errors.

```dart
final class IOError extends FailureType {
  final String? operation;
  final String? path;

  String get category => "I/O Error";
}
```

**Detection Patterns:**
- `FileSystemException`
- `PathNotFoundException`
- `Cannot open file`

**Example:**
```dart
case IOError(:final operation, :final path):
  print('IO operation "$operation" failed on path: $path');
```

**Common Fixes:**
- Check file/directory exists
- Verify permissions
- Use test fixtures instead of real files
- Mock file system operations

---

### NetworkError

HTTP and network failures.

```dart
final class NetworkError extends FailureType {
  final String? operation;
  final String? endpoint;
  final int? statusCode;

  String get category => "Network Error";
}
```

**Detection Patterns:**
- `SocketException`
- `HttpException`
- `Connection refused`
- HTTP status codes (4xx, 5xx)

**Example:**
```dart
case NetworkError(:final endpoint, :final statusCode):
  print('Network call to $endpoint failed with status $statusCode');
```

**Common Fixes:**
- Mock HTTP client
- Use test server
- Add retry logic
- Check network availability in tests

---

### UnknownFailure

Unclassified failures.

```dart
final class UnknownFailure extends FailureType {
  final String message;

  String get category => "Unknown";
}
```

**Example:**
```dart
case UnknownFailure(:final message):
  print('Unclassified failure: $message');
```

---

## Pattern Matching

### Exhaustive Switch

The compiler enforces handling all cases:

```dart
String handleFailure(FailureType failure) => switch (failure) {
  AssertionFailure(:final message) => 'Assertion: $message',
  NullError(:final variableName) => 'Null on: $variableName',
  TimeoutFailure(:final duration) => 'Timeout: $duration',
  RangeError(:final index) => 'Index out of bounds: $index',
  TypeError(:final expectedType, :final actualType) =>
    'Type mismatch: $actualType is not $expectedType',
  IOError(:final path) => 'IO error on: $path',
  NetworkError(:final endpoint) => 'Network error: $endpoint',
  UnknownFailure(:final message) => 'Unknown: $message',
};
```

### Selective Matching

Handle specific types, group others:

```dart
String quickFix(FailureType failure) => switch (failure) {
  NullError() => 'Add null check',
  TimeoutFailure() => 'Increase timeout',
  AssertionFailure() || TypeError() => 'Check test expectations',
  _ => 'Review error details',
};
```

### Field Extraction

Extract multiple fields at once:

```dart
void logFailure(FailureType failure) {
  switch (failure) {
    case AssertionFailure(
      :final message,
      :final expectedValue,
      :final actualValue,
      :final location,
    ):
      print('At $location:');
      print('  Expected: $expectedValue');
      print('  Actual: $actualValue');
      print('  Message: $message');
    case NullError(:final variableName, :final location):
      print('Null error on $variableName at $location');
    // ... other cases
  }
}
```

---

## Detection Function

Use `detectFailureType` to automatically classify errors:

```dart
import 'package:test_reporter/test_reporter.dart';

void main() {
  final error = 'Expected: 42\nActual: 0';
  final stackTrace = 'at test/example_test.dart:15:5';

  final failure = detectFailureType(error, stackTrace);

  print(failure.category);    // "Assertion Failure"
  print(failure.suggestion);  // Fix suggestion

  // Pattern match for specific handling
  if (failure case AssertionFailure(:final expectedValue, :final actualValue)) {
    print('Expected $expectedValue but got $actualValue');
  }
}
```

---

## Adding Custom Handling

Extend with your own logic:

```dart
extension FailureTypeExtensions on FailureType {
  String get emoji => switch (this) {
    AssertionFailure() => '❌',
    NullError() => '🚫',
    TimeoutFailure() => '⏰',
    RangeError() => '📏',
    TypeError() => '🔄',
    IOError() => '📁',
    NetworkError() => '🌐',
    UnknownFailure() => '❓',
  };

  int get severity => switch (this) {
    NullError() || TypeError() => 3,  // High
    AssertionFailure() || RangeError() => 2,  // Medium
    TimeoutFailure() || IOError() || NetworkError() => 1,  // Low
    UnknownFailure() => 0,  // Unknown
  };
}
```

---

## Best Practices

1. **Always handle all cases** - The compiler helps, but be thorough
2. **Extract relevant fields** - Use destructuring for cleaner code
3. **Group similar handling** - Use `||` patterns for shared logic
4. **Add context** - Include location and values in error messages
5. **Use suggestions** - The `suggestion` property provides actionable fixes
