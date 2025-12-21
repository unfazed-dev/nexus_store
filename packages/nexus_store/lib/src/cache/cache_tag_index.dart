/// Bidirectional index mapping tags to IDs and IDs to tags.
///
/// Provides O(1) lookup for both directions.
class CacheTagIndex<ID> {
  /// Map from tag to set of IDs.
  final Map<String, Set<ID>> _tagToIds = {};

  /// Map from ID to set of tags.
  final Map<ID, Set<String>> _idToTags = {};

  /// Adds tags to an ID.
  void addTags(ID id, Set<String> tags) {
    if (tags.isEmpty) return;

    // Add to ID → tags mapping
    _idToTags.putIfAbsent(id, () => {}).addAll(tags);

    // Add to tag → IDs mapping
    for (final tag in tags) {
      _tagToIds.putIfAbsent(tag, () => {}).add(id);
    }
  }

  /// Removes tags from an ID.
  void removeTags(ID id, Set<String> tags) {
    final currentTags = _idToTags[id];
    if (currentTags == null) return;

    for (final tag in tags) {
      currentTags.remove(tag);
      _tagToIds[tag]?.remove(id);

      // Clean up empty tag sets
      if (_tagToIds[tag]?.isEmpty ?? false) {
        _tagToIds.remove(tag);
      }
    }

    // Clean up empty ID sets
    if (currentTags.isEmpty) {
      _idToTags.remove(id);
    }
  }

  /// Removes an ID from all tags.
  void removeId(ID id) {
    final tags = _idToTags.remove(id);
    if (tags == null) return;

    for (final tag in tags) {
      _tagToIds[tag]?.remove(id);

      // Clean up empty tag sets
      if (_tagToIds[tag]?.isEmpty ?? false) {
        _tagToIds.remove(tag);
      }
    }
  }

  /// Gets all tags for an ID.
  Set<String> getTagsForId(ID id) {
    return Set.unmodifiable(_idToTags[id] ?? {});
  }

  /// Gets all IDs with a specific tag.
  Set<ID> getIdsByTag(String tag) {
    return Set.unmodifiable(_tagToIds[tag] ?? {});
  }

  /// Gets all IDs that have any of the given tags (union).
  Set<ID> getIdsByAnyTag(Set<String> tags) {
    if (tags.isEmpty) return {};

    final result = <ID>{};
    for (final tag in tags) {
      result.addAll(_tagToIds[tag] ?? {});
    }
    return result;
  }

  /// Gets all IDs that have all of the given tags (intersection).
  Set<ID> getIdsByAllTags(Set<String> tags) {
    if (tags.isEmpty) return {};

    Set<ID>? result;
    for (final tag in tags) {
      final ids = _tagToIds[tag];
      if (ids == null || ids.isEmpty) return {};

      if (result == null) {
        result = Set<ID>.from(ids);
      } else {
        result = result.intersection(ids);
        if (result.isEmpty) return {};
      }
    }
    return result ?? {};
  }

  /// Clears all tags and mappings.
  void clear() {
    _tagToIds.clear();
    _idToTags.clear();
  }

  /// Returns true if no IDs have tags.
  bool get isEmpty => _idToTags.isEmpty;

  /// Returns all unique tags in the index.
  Set<String> get allTags => Set.unmodifiable(_tagToIds.keys.toSet());

  /// Returns all IDs that have tags.
  Set<ID> get allIds => Set.unmodifiable(_idToTags.keys.toSet());
}
