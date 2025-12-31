import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:nexus_store/nexus_store.dart' show Lazy, NexusLazy;
import 'package:source_gen/source_gen.dart';

/// Type checker for Lazy annotation.
const _lazyChecker = TypeChecker.fromRuntime(Lazy);

/// Generator for lazy field accessors.
///
/// Reads classes annotated with `@NexusLazy` and generates:
/// - A mixin with typed accessor methods for each `@Lazy` field
/// - A wrapper class extending `LazyEntity` (if generateWrapper is true)
class LazyGenerator extends GeneratorForAnnotation<NexusLazy> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@NexusLazy can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;

    final generateAccessors = annotation.read('generateAccessors').boolValue;
    final generateWrapper = annotation.read('generateWrapper').boolValue;

    // Find all fields with @Lazy annotation
    final lazyFields = _findLazyFields(classElement);

    if (lazyFields.isEmpty) {
      log.warning('$className has @NexusLazy but no @Lazy fields.');
      return '';
    }

    final buffer = StringBuffer()
      ..writeln("import 'package:nexus_store/nexus_store.dart';")
      ..writeln();

    // Generate accessor mixin
    if (generateAccessors) {
      buffer.writeln(_generateAccessorMixin(className, lazyFields));
    }

    // Generate wrapper class
    if (generateWrapper) {
      buffer.writeln(
        _generateWrapperClass(className, lazyFields, generateAccessors),
      );
    }

    return buffer.toString();
  }

  /// Finds all fields annotated with @Lazy.
  List<_LazyFieldInfo> _findLazyFields(ClassElement classElement) {
    final lazyFields = <_LazyFieldInfo>[];

    for (final field in classElement.fields) {
      final annotation = _lazyChecker.firstAnnotationOf(field);
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        lazyFields.add(
          _LazyFieldInfo(
            name: field.name,
            typeName: field.type.getDisplayString(withNullability: true),
            placeholder: reader.read('placeholder').isNull
                ? null
                : reader.read('placeholder').literalValue,
            preloadOnWatch: reader.read('preloadOnWatch').boolValue,
          ),
        );
      }
    }

    return lazyFields;
  }

  /// Generates the accessor mixin.
  String _generateAccessorMixin(
    String className,
    List<_LazyFieldInfo> fields,
  ) {
    final buffer = StringBuffer()
      ..writeln('/// Mixin providing typed lazy field accessors for '
          '[$className].')
      ..writeln('///')
      ..writeln('/// Use this mixin with a [LazyEntity] to get strongly-typed')
      ..writeln('/// accessor methods for lazy fields.')
      ..writeln('mixin ${className}LazyAccessors {')
      ..writeln('  /// Loads a field by name. '
          'Must be implemented by the target class.')
      ..writeln('  Future<dynamic> loadField(String fieldName);')
      ..writeln()
      ..writeln('  /// Checks if a field is loaded. '
          'Must be implemented by the target class.')
      ..writeln('  bool isFieldLoaded(String fieldName);')
      ..writeln();

    for (final field in fields) {
      final methodName = 'load${_capitalize(field.name)}';
      final checkMethodName = 'is${_capitalize(field.name)}Loaded';

      buffer
        ..writeln('  /// Loads the [${field.name}] field.')
        ..writeln('  ///')
        ..writeln('  /// Returns the loaded value of type `${field.typeName}`.')
        ..writeln("  @LazyAccessor('${field.name}', "
            "returnType: '${field.typeName}')")
        ..writeln('  Future<dynamic> $methodName() => '
            "loadField('${field.name}');")
        ..writeln()
        ..writeln('  /// Returns `true` if [${field.name}] has been loaded.')
        ..writeln('  bool get $checkMethodName => '
            "isFieldLoaded('${field.name}');")
        ..writeln();
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates the wrapper class.
  String _generateWrapperClass(
    String className,
    List<_LazyFieldInfo> fields,
    bool includeAccessors,
  ) {
    final buffer = StringBuffer();
    final wrapperName = 'Lazy$className';

    // Build the lazy fields set
    final lazyFieldNames = fields.map((f) => "'${f.name}'").join(', ');

    // Build placeholders map
    final placeholders = fields
        .where((f) => f.placeholder != null)
        .map((f) => "'${f.name}': ${_literalValue(f.placeholder)}")
        .join(', ');

    buffer
      ..writeln('/// A lazy-loading wrapper for [$className].')
      ..writeln('///')
      ..writeln('/// Provides on-demand loading for the following fields:');

    for (final field in fields) {
      buffer.writeln('/// - [${field.name}]');
    }

    buffer.writeln('class $wrapperName extends LazyEntity<$className, String>');

    if (includeAccessors) {
      buffer.writeln('    with ${className}LazyAccessors {');
    } else {
      buffer.writeln('    {');
    }

    buffer
      ..writeln('  /// Creates a lazy wrapper for a [$className] instance.')
      ..writeln('  $wrapperName(')
      ..writeln('    $className entity, {')
      ..writeln('    required FieldLoader<$className, String> fieldLoader,')
      ..writeln('  }) : super(')
      ..writeln('          entity,')
      ..writeln('          idExtractor: (e) => e.id,')
      ..writeln('          fieldLoader: fieldLoader,')
      ..writeln('          config: const LazyLoadConfig(')
      ..writeln('            lazyFields: {$lazyFieldNames},');

    if (placeholders.isNotEmpty) {
      buffer.writeln('            placeholders: {$placeholders},');
    }

    buffer
      ..writeln('          ),')
      ..writeln('        );');

    // Add preloadOnWatch fields getter
    final preloadFields = fields.where((f) => f.preloadOnWatch).toList();
    if (preloadFields.isNotEmpty) {
      final preloadFieldNames =
          preloadFields.map((f) => "'${f.name}'").join(', ');
      buffer
        ..writeln()
        ..writeln('  /// Fields configured for automatic preloading.')
        ..writeln('  static const Set<String> preloadOnWatchFields = '
            '{$preloadFieldNames};');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _literalValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return "'$value'";
    if (value is num || value is bool) return value.toString();
    return value.toString();
  }
}

/// Information about a lazy field.
class _LazyFieldInfo {
  const _LazyFieldInfo({
    required this.name,
    required this.typeName,
    this.placeholder,
    this.preloadOnWatch = false,
  });

  final String name;
  final String typeName;
  final Object? placeholder;
  final bool preloadOnWatch;
}
