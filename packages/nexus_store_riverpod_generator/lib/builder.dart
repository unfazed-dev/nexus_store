import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

/// Builder factory for the NexusStore Riverpod generator.
///
/// This builder generates Riverpod providers for functions annotated with
/// `@riverpodNexusStore`.
///
/// ## Usage
///
/// Add the generator to your `pubspec.yaml`:
///
/// ```yaml
/// dev_dependencies:
///   nexus_store_riverpod_generator: ^0.1.0
///   build_runner: ^2.4.0
/// ```
///
/// Then run `dart run build_runner build` to generate providers.
Builder nexusStoreRiverpodBuilder(BuilderOptions options) => SharedPartBuilder(
      [NexusStoreRiverpodGenerator()],
      'nexus_store_riverpod',
    );
