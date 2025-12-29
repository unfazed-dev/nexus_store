import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/schema_validation_config.dart';

void main() {
  group('SchemaValidationMode', () {
    test('has strict mode', () {
      expect(SchemaValidationMode.strict, isNotNull);
    });

    test('has warn mode', () {
      expect(SchemaValidationMode.warn, isNotNull);
    });

    test('has silent mode', () {
      expect(SchemaValidationMode.silent, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(SchemaValidationMode.values.length, equals(3));
    });

    group('isStrict', () {
      test('returns true for strict mode', () {
        expect(SchemaValidationMode.strict.isStrict, isTrue);
      });

      test('returns false for warn mode', () {
        expect(SchemaValidationMode.warn.isStrict, isFalse);
      });

      test('returns false for silent mode', () {
        expect(SchemaValidationMode.silent.isStrict, isFalse);
      });
    });

    group('isWarn', () {
      test('returns false for strict mode', () {
        expect(SchemaValidationMode.strict.isWarn, isFalse);
      });

      test('returns true for warn mode', () {
        expect(SchemaValidationMode.warn.isWarn, isTrue);
      });

      test('returns false for silent mode', () {
        expect(SchemaValidationMode.silent.isWarn, isFalse);
      });
    });

    group('isSilent', () {
      test('returns false for strict mode', () {
        expect(SchemaValidationMode.strict.isSilent, isFalse);
      });

      test('returns false for warn mode', () {
        expect(SchemaValidationMode.warn.isSilent, isFalse);
      });

      test('returns true for silent mode', () {
        expect(SchemaValidationMode.silent.isSilent, isTrue);
      });
    });

    group('shouldThrow', () {
      test('returns true for strict mode', () {
        expect(SchemaValidationMode.strict.shouldThrow, isTrue);
      });

      test('returns false for warn mode', () {
        expect(SchemaValidationMode.warn.shouldThrow, isFalse);
      });

      test('returns false for silent mode', () {
        expect(SchemaValidationMode.silent.shouldThrow, isFalse);
      });
    });

    group('shouldLog', () {
      test('returns true for strict mode', () {
        expect(SchemaValidationMode.strict.shouldLog, isTrue);
      });

      test('returns true for warn mode', () {
        expect(SchemaValidationMode.warn.shouldLog, isTrue);
      });

      test('returns false for silent mode', () {
        expect(SchemaValidationMode.silent.shouldLog, isFalse);
      });
    });
  });

  group('SchemaValidationConfig', () {
    group('defaults', () {
      test('has warn mode by default', () {
        const config = SchemaValidationConfig();
        expect(config.mode, equals(SchemaValidationMode.warn));
      });

      test('is enabled by default', () {
        const config = SchemaValidationConfig();
        expect(config.enabled, isTrue);
      });

      test('validates on save by default', () {
        const config = SchemaValidationConfig();
        expect(config.validateOnSave, isTrue);
      });

      test('does not validate on read by default', () {
        const config = SchemaValidationConfig();
        expect(config.validateOnRead, isFalse);
      });
    });

    group('presets', () {
      group('defaults preset', () {
        test('matches default constructor', () {
          expect(
            SchemaValidationConfig.defaults,
            equals(const SchemaValidationConfig()),
          );
        });
      });

      group('strict preset', () {
        test('has strict mode', () {
          expect(
            SchemaValidationConfig.strict.mode,
            equals(SchemaValidationMode.strict),
          );
        });

        test('validates on save and read', () {
          expect(SchemaValidationConfig.strict.validateOnSave, isTrue);
          expect(SchemaValidationConfig.strict.validateOnRead, isTrue);
        });
      });

      group('lenient preset', () {
        test('has warn mode', () {
          expect(
            SchemaValidationConfig.lenient.mode,
            equals(SchemaValidationMode.warn),
          );
        });

        test('validates only on save', () {
          expect(SchemaValidationConfig.lenient.validateOnSave, isTrue);
          expect(SchemaValidationConfig.lenient.validateOnRead, isFalse);
        });
      });

      group('disabled preset', () {
        test('has enabled set to false', () {
          expect(SchemaValidationConfig.disabled.enabled, isFalse);
        });
      });
    });

    group('custom values', () {
      test('can create with strict mode', () {
        const config = SchemaValidationConfig(
          mode: SchemaValidationMode.strict,
        );
        expect(config.mode, equals(SchemaValidationMode.strict));
      });

      test('can create with silent mode', () {
        const config = SchemaValidationConfig(
          mode: SchemaValidationMode.silent,
        );
        expect(config.mode, equals(SchemaValidationMode.silent));
      });

      test('can create with custom validation flags', () {
        const config = SchemaValidationConfig(
          validateOnSave: false,
          validateOnRead: true,
        );
        expect(config.validateOnSave, isFalse);
        expect(config.validateOnRead, isTrue);
      });

      test('can create with all custom values', () {
        const config = SchemaValidationConfig(
          mode: SchemaValidationMode.strict,
          enabled: false,
          validateOnSave: false,
          validateOnRead: true,
        );
        expect(config.mode, equals(SchemaValidationMode.strict));
        expect(config.enabled, isFalse);
        expect(config.validateOnSave, isFalse);
        expect(config.validateOnRead, isTrue);
      });
    });

    group('copyWith', () {
      test('can update mode', () {
        const original = SchemaValidationConfig();
        final updated = original.copyWith(
          mode: SchemaValidationMode.strict,
        );
        expect(updated.mode, equals(SchemaValidationMode.strict));
        expect(updated.enabled, equals(original.enabled));
      });

      test('can update multiple values', () {
        const original = SchemaValidationConfig();
        final updated = original.copyWith(
          mode: SchemaValidationMode.silent,
          enabled: false,
        );
        expect(updated.mode, equals(SchemaValidationMode.silent));
        expect(updated.enabled, isFalse);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = SchemaValidationConfig(
          mode: SchemaValidationMode.strict,
        );
        const config2 = SchemaValidationConfig(
          mode: SchemaValidationMode.strict,
        );
        expect(config1, equals(config2));
      });

      test('different configs are not equal', () {
        const config1 = SchemaValidationConfig(
          mode: SchemaValidationMode.strict,
        );
        const config2 = SchemaValidationConfig(
          mode: SchemaValidationMode.warn,
        );
        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
