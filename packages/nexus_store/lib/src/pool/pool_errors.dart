// Re-export pool errors from store_errors.dart.
//
// Pool errors are defined in store_errors.dart because sealed classes
// can only be extended within the same library.
export '../errors/store_errors.dart'
    show
        PoolError,
        PoolNotInitializedError,
        PoolDisposedError,
        PoolAcquireTimeoutError,
        PoolClosedError,
        PoolExhaustedError,
        PoolConnectionError;
