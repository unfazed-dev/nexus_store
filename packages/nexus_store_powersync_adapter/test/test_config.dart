// ignore_for_file: lines_longer_than_80_chars

/// Test configuration for PowerSync integration tests.
///
/// These credentials are for testing purposes only.
class TestConfig {
  TestConfig._();

  // Supabase configuration
  static const supabaseUrl = 'https://ohfsnnhytsfwjdywsqdc.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oZnNubmh5dHNmd2pkeXdzcWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk3MTAsImV4cCI6MjA4MTQ2NTcxMH0.NRyLSwzscRjytXho60CIEDHdwXOV0jrdkdI2sROJJaU';

  // PowerSync configuration
  static const powersyncUrl =
      'https://6955fb487e2a07e6df81e899.powersync.journeyapps.com';
  static const powersyncToken =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiJyZXF1ZXN0LnVzZXJfaWQiLCJpYXQiOjE3NjcyNDQ5NzMsImlzcyI6Imh0dHBzOi8vcG93ZXJzeW5jLWFwaS5qb3VybmV5YXBwcy5jb20iLCJhdWQiOiJodHRwczovLzY5NTVmYjQ4N2UyYTA3ZTZkZjgxZTg5OS5wb3dlcnN5bmMuam91cm5leWFwcHMuY29tIiwiZXhwIjoxNzY3Mjg4MTczfQ.GNoC3hAqUr5XwZeSJGYMapMPv-TTYEUXWkDq8K20ueK2PtjGxgWrVTUIBTOTNgqfhF5I2Oubx0dbj9LTZPS1QMmqh0MNU6YEYGXk6fPlr6RAwqeAwhzcs9tCsfjFhCHI-sO8S-ck3Zs2Skv4cPWfsgZAg9g1T3sV5ljbM1MvHPYiDQTrQgVy2LjKQnUmbYT6-ei0jDtL7DZMuo3EuwUoh011zab0Dhu9INvNNRLwLq_S7MIsy_LxzFHyd-AJOKEKrs-Wd8obmR0twlqYceRCFoN_G0FEE7-UlY1Y9RECbgcUbBo3tVQWLibVSAZ7DTE7K_CtXPparCsw1ctdHlqyAA';

  // Database path for local SQLite
  static String get testDatabasePath => 'test_powersync.db';
}
