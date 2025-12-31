import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:nexus_store/nexus_store.dart' show NexusEntity;
import 'package:source_gen/source_gen.dart';

/// Generator for entity field accessors.
///
/// Reads classes annotated with `@NexusEntity` and generates:
/// - A `$ModelFields` class with static typed field accessors
class EntityGenerator extends GeneratorForAnnotation<NexusEntity> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@NexusEntity can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;

    final generateFields = annotation.read('generateFields').boolValue;
    final fieldsSuffix = annotation.read('fieldsSuffix').stringValue;

    if (!generateFields) {
      return '';
    }

    // Collect all instance fields (excluding static)
    final fields = _collectFields(classElement);

    if (fields.isEmpty) {
      log.warning('$className has @NexusEntity but no fields to generate.');
      return '';
    }

    return _generateFieldsClass(
      className: className,
      suffix: fieldsSuffix,
      fields: fields,
    );
  }

  /// Collects all instance fields from the class.
  List<_FieldInfo> _collectFields(ClassElement classElement) {
    final fields = <_FieldInfo>[];

    for (final field in classElement.fields) {
      // Skip static and synthetic fields
      if (field.isStatic || field.isSynthetic) continue;

      fields.add(_analyzeField(field));
    }

    return fields;
  }

  /// Analyzes a field and determines its appropriate Field type.
  _FieldInfo _analyzeField(FieldElement field) {
    final type = field.type;

    // Determine the appropriate Field class
    final (fieldClass, typeArgs) = _mapTypeToFieldClass(type);

    return _FieldInfo(
      name: field.name,
      fieldClass: fieldClass,
      typeArgs: typeArgs,
    );
  }

  /// Maps a Dart type to the appropriate Field class.
  (String fieldClass, String typeArgs) _mapTypeToFieldClass(DartType type) {
    // ignore: deprecated_member_use
    final typeName = type.getDisplayString(withNullability: false);

    // Check for String
    if (typeName == 'String') {
      return ('StringField', '');
    }

    // Check for List<E>
    if (type.isDartCoreList && type is InterfaceType) {
      final elementType = type.typeArguments.isNotEmpty
          // ignore: deprecated_member_use
          ? type.typeArguments.first.getDisplayString(withNullability: false)
          : 'dynamic';
      return ('ListField', ', $elementType');
    }

    // Check for Comparable types (int, double, num, DateTime, Duration)
    if (_isComparableType(typeName)) {
      return ('ComparableField', ', $typeName');
    }

    // Default to base Field
    return ('Field', ', $typeName');
  }

  bool _isComparableType(String typeName) => const {
        'int',
        'double',
        'num',
        'DateTime',
        'Duration',
      }.contains(typeName);

  /// Generates the Fields class.
  String _generateFieldsClass({
    required String className,
    required String suffix,
    required List<_FieldInfo> fields,
  }) {
    final fieldsClassName = '$className$suffix';

    final buffer = StringBuffer()
      ..writeln("import 'package:nexus_store/nexus_store.dart';")
      ..writeln()
      ..writeln('/// Type-safe field accessors for [$className].')
      ..writeln('///')
      ..writeln(
          '/// Use these fields with [Query<$className>] for compile-time',)
      ..writeln('/// validated queries.')
      ..writeln('///')
      ..writeln('/// ## Example')
      ..writeln('///')
      ..writeln('/// ```dart')
      ..writeln('/// final query = Query<$className>()')
      ..writeln(
        '///   .whereExpression($fieldsClassName.${fields.first.name}.equals(...));',
      )
      ..writeln('/// ```')
      ..writeln('class $fieldsClassName extends Fields<$className> {')
      ..writeln('  $fieldsClassName._();')
      ..writeln()
      ..writeln('  /// Singleton instance of [$fieldsClassName].')
      ..writeln('  static const instance = $fieldsClassName._();')
      ..writeln();

    for (final field in fields) {
      buffer
        ..writeln('  /// Field accessor for [${field.name}].')
        ..writeln(
          '  static final ${field.name} = '
          '${field.fieldClass}<$className${field.typeArgs}>'
          "('${field.name}');",
        )
        ..writeln();
    }

    buffer.writeln('}');

    return buffer.toString();
  }
}

/// Information about a field.
class _FieldInfo {
  const _FieldInfo({
    required this.name,
    required this.fieldClass,
    required this.typeArgs,
  });

  final String name;
  final String fieldClass;
  final String typeArgs;
}
