import 'interceptor_context.dart';
import 'interceptor_result.dart';
import 'store_interceptor.dart';
import 'store_operation.dart';

/// Exception thrown when validation fails.
class ValidationException implements Exception {
  /// Creates a validation exception.
  const ValidationException(this.message, {this.errors = const []});

  /// The validation error message.
  final String message;

  /// Individual validation errors (for multiple field validation).
  final List<String> errors;

  @override
  String toString() => 'ValidationException: $message';
}

/// Type definition for validation functions.
///
/// Returns `null` if valid, or an error message if invalid.
typedef Validator<T> = String? Function(T item);

/// Type definition for custom error factory functions.
typedef ErrorFactory = Object Function(String message);

/// An interceptor that validates items before save operations.
///
/// Runs a validation function on items before they are saved. If validation
/// fails, the operation is short-circuited with an error.
///
/// ## Example
///
/// ```dart
/// final store = NexusStore(
///   backend: backend,
///   config: StoreConfig(
///     interceptors: [
///       ValidationInterceptor<User>(
///         validate: (user) {
///           if (user.name.isEmpty) return 'Name is required';
///           if (user.email == null) return 'Email is required';
///           return null; // Valid
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class ValidationInterceptor<T> extends StoreInterceptor {
  /// Creates a validation interceptor.
  ///
  /// - [validate]: Function that validates an item. Return `null` if valid,
  ///   or an error message if invalid.
  /// - [operations]: Operations to validate. Defaults to save and saveAll.
  /// - [errorFactory]: Custom factory for creating error objects.
  ValidationInterceptor({
    required this.validate,
    Set<StoreOperation>? operations,
    this.errorFactory,
  }) : _operations =
            operations ?? {StoreOperation.save, StoreOperation.saveAll};

  /// The validation function.
  final Validator<T> validate;

  /// Custom error factory. If not provided, [ValidationException] is used.
  final ErrorFactory? errorFactory;

  final Set<StoreOperation> _operations;

  @override
  Set<StoreOperation> get operations => _operations;

  @override
  Future<InterceptorResult<R>> onRequest<TReq, R>(
    InterceptorContext<TReq, R> ctx,
  ) async {
    final request = ctx.request;

    // Handle save operation (single item)
    if (ctx.operation == StoreOperation.save && request is T) {
      final error = validate(request);
      if (error != null) {
        return InterceptorResult.error(
          _createError(error, [error]),
          StackTrace.current,
        );
      }
    }

    // Handle saveAll operation (list of items)
    if (ctx.operation == StoreOperation.saveAll && request is List) {
      final errors = <String>[];
      for (final item in request) {
        if (item is T) {
          final error = validate(item);
          if (error != null) {
            errors.add(error);
          }
        }
      }

      if (errors.isNotEmpty) {
        return InterceptorResult.error(
          _createError(errors.join('; '), errors),
          StackTrace.current,
        );
      }
    }

    return const InterceptorResult.continue_();
  }

  Object _createError(String message, List<String> errors) {
    if (errorFactory != null) {
      return errorFactory!(message);
    }
    return ValidationException(message, errors: errors);
  }
}
