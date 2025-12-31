# nexus_store_generator

[![Pub Version](https://img.shields.io/pub/v/nexus_store_generator)](https://pub.dev/packages/nexus_store_generator)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Code generator for nexus_store lazy field accessors. Automatically generates typed accessor methods and wrapper classes for lazy-loaded fields.

## Features

- Generates typed accessor mixin with `load{FieldName}()` and `is{FieldName}Loaded` methods
- Generates `Lazy{ClassName}` wrapper class extending `LazyEntity`
- Supports placeholder values for unloaded fields
- Configurable preload-on-watch behavior
- Integrates seamlessly with build_runner

## Installation

Add this package as a dev dependency:

```yaml
dependencies:
  nexus_store: ^0.1.0

dev_dependencies:
  nexus_store_generator: ^0.1.0
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate your entities

Mark your class with `@NexusLazy` and fields with `@Lazy`:

```dart
import 'package:nexus_store/nexus_store.dart';

@NexusLazy()
class MediaItem {
  final String id;
  final String name;

  @Lazy(placeholder: 'loading.png')
  final String? thumbnail;

  @Lazy(preloadOnWatch: true)
  final Uint8List? fullResolutionImage;

  MediaItem({
    required this.id,
    required this.name,
    this.thumbnail,
    this.fullResolutionImage,
  });
}
```

### 2. Run the generator

```bash
dart run build_runner build
```

Or for watch mode during development:

```bash
dart run build_runner watch
```

### 3. Use the generated code

The generator creates a `.lazy.dart` file with:

```dart
// media_item.lazy.dart (generated)
import 'package:nexus_store/nexus_store.dart';

/// Mixin providing typed lazy field accessors for [MediaItem].
mixin MediaItemLazyAccessors {
  Future<dynamic> loadField(String fieldName);
  bool isFieldLoaded(String fieldName);

  /// Loads the [thumbnail] field.
  @LazyAccessor('thumbnail', returnType: 'String?')
  Future<dynamic> loadThumbnail() => loadField('thumbnail');

  /// Returns `true` if [thumbnail] has been loaded.
  bool get isThumbnailLoaded => isFieldLoaded('thumbnail');

  /// Loads the [fullResolutionImage] field.
  @LazyAccessor('fullResolutionImage', returnType: 'Uint8List?')
  Future<dynamic> loadFullResolutionImage() => loadField('fullResolutionImage');

  /// Returns `true` if [fullResolutionImage] has been loaded.
  bool get isFullResolutionImageLoaded => isFieldLoaded('fullResolutionImage');
}

/// A lazy-loading wrapper for [MediaItem].
class LazyMediaItem extends LazyEntity<MediaItem, String>
    with MediaItemLazyAccessors {
  LazyMediaItem(
    MediaItem entity, {
    required FieldLoader<MediaItem, String> fieldLoader,
  }) : super(
          entity,
          idExtractor: (e) => e.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'thumbnail', 'fullResolutionImage'},
            placeholders: {'thumbnail': 'loading.png'},
          ),
        );

  static const Set<String> preloadOnWatchFields = {'fullResolutionImage'};
}
```

### 4. Use the wrapper in your code

```dart
// Create a lazy wrapper for your entity
final lazyMedia = LazyMediaItem(
  mediaItem,
  fieldLoader: (entity, fieldName) async {
    return backend.loadField(entity.id, fieldName);
  },
);

// Check if field is loaded
print(lazyMedia.isThumbnailLoaded); // false

// Load the field
final thumbnail = await lazyMedia.loadThumbnail();

// Field is now loaded
print(lazyMedia.isThumbnailLoaded); // true
```

## Annotations

### @NexusLazy

Marks a class for lazy loading code generation.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `generateAccessors` | `bool` | `true` | Generate typed accessor mixin |
| `generateWrapper` | `bool` | `true` | Generate `LazyEntity` wrapper class |

### @Lazy

Marks a field as lazy-loaded.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `placeholder` | `Object?` | `null` | Default value when field is not loaded |
| `preloadOnWatch` | `bool` | `false` | Auto-load when entity is watched |

## Configuration

### Disable wrapper generation

```dart
@NexusLazy(generateWrapper: false)
class User {
  @Lazy()
  final String? avatar;
  // ...
}
// Only generates UserLazyAccessors mixin
```

### Disable accessor generation

```dart
@NexusLazy(generateAccessors: false)
class User {
  @Lazy()
  final String? avatar;
  // ...
}
// Only generates LazyUser wrapper class
```

## Build Configuration

The generator automatically applies to dependents. The default configuration in `build.yaml`:

```yaml
builders:
  lazy:
    import: "package:nexus_store_generator/builder.dart"
    builder_factories: ["lazyBuilder"]
    build_extensions: {".dart": [".lazy.dart"]}
    auto_apply: dependents
    build_to: source
```

## License

See repository license.
