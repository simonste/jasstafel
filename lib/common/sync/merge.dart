import 'package:collection/collection.dart';

const _equality = DeepCollectionEquality();

/// Merges two JSON values [ours] and [theirs] that were both changed from
/// [base], keeping the changes of both.
///
/// - Maps are merged key by key.
/// - Lists that both sides grew keep the entries both appended, which covers
///   rounds entered on two devices at once. Their existing entries are merged
///   one by one.
/// - Integers both sides changed add up both changes if they are [counters],
///   such as strokes.
/// - Anything else both sides changed takes [theirs].
Object? mergeJson(
  Object? base,
  Object? ours,
  Object? theirs, {
  bool counters = true,
}) {
  if (_equality.equals(ours, base)) return theirs;
  if (_equality.equals(theirs, base)) return ours;
  if (base is Map && ours is Map && theirs is Map) {
    return <String, dynamic>{
      for (final key in {...ours.keys, ...theirs.keys}.cast<String>())
        key: mergeJson(base[key], ours[key], theirs[key], counters: counters),
    };
  }
  if (base is List && ours is List && theirs is List) {
    if (ours.length < base.length || theirs.length < base.length) {
      // An entry was removed, so entries can't be matched up anymore.
      return theirs;
    }
    return [
      for (var i = 0; i < base.length; i++)
        mergeJson(base[i], ours[i], theirs[i], counters: counters),
      ...ours.sublist(base.length),
      ...theirs.sublist(base.length),
    ];
  }
  if (counters && base is int && ours is int && theirs is int) {
    return ours + theirs - base;
  }
  return theirs;
}
