import 'package:build/build.dart';
import 'package:nexus_store_entity_generator/src/entity_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Creates the builder for generating entity field accessors.
///
/// This is the entry point for build_runner.
Builder entityBuilder(BuilderOptions options) => LibraryBuilder(
      EntityGenerator(),
      generatedExtension: '.entity.dart',
    );
