# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_bloc_binding
- `NexusStoreCubit<T, ID>` for list data management
- `NexusItemCubit<T, ID>` for single item management
- `NexusStoreState` sealed class (Initial, Loading, Loaded, Error)
- `NexusItemState` sealed class (Initial, Loading, Loaded, NotFound, Error)
- `NexusStoreBlocObserver` for debugging and logging
- Automatic stream subscription management
- Policy support for save and delete operations
