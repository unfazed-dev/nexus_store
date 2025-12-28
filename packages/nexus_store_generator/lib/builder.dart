import 'package:build/build.dart';
import 'package:nexus_store_generator/src/lazy_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Creates the builder for generating lazy field accessors.
///
/// This is the entry point for build_runner.
Builder lazyBuilder(BuilderOptions options) => LibraryBuilder(
      LazyGenerator(),
      generatedExtension: '.lazy.dart',
    );
