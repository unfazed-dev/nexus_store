/// Encryption algorithms supported for field-level encryption.
enum EncryptionAlgorithm {
  /// AES-256-GCM (recommended).
  ///
  /// Provides authenticated encryption with associated data (AEAD).
  /// Best for most use cases due to built-in integrity verification.
  aes256Gcm,

  /// AES-256-CBC (legacy).
  ///
  /// Classic block cipher mode. Use only for compatibility with existing
  /// systems. Requires separate MAC for integrity.
  aes256Cbc,

  /// ChaCha20-Poly1305 (mobile-optimized).
  ///
  /// Software-based cipher that performs well on devices without
  /// hardware AES acceleration. Good choice for older mobile devices.
  chaCha20Poly1305,
}
