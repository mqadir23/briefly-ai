import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/summary.dart';
import '../utils/constants.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<Summary>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<Summary>> {
  HistoryNotifier() : super([]) { _load(); }

  Box<Summary> get _box => Hive.box<Summary>(AppConstants.hiveBoxHistory);

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(Summary summary) async {
    await _box.put(summary.id, summary);
    _load();
  }

  Future<void> toggleBookmark(String id) async {
    final s = _box.get(id);
    if (s == null) return;
    final updated = s.copyWith(isBookmarked: !s.isBookmarked);
    await _box.put(id, updated);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = [];
  }

  /// Persists a translation for an existing summary (called from ArticleDetailScreen).
  Future<void> updateTranslation(
    String id, {
    required String translatedHeadline,
    required List<String> translatedBullets,
    required String translatedTo,
  }) async {
    final s = _box.get(id);
    if (s == null) return;
    final updated = s.copyWith(
      translatedHeadline: translatedHeadline,
      translatedBullets:  translatedBullets,
      translatedTo:       translatedTo,
    );
    await _box.put(id, updated);
    _load();
  }

  /// Removes the bookmark flag from every summary (used in Settings).
  Future<void> clearBookmarks() async {
    final bookmarked = _box.values.where((s) => s.isBookmarked).toList();
    for (final s in bookmarked) {
      await _box.put(s.id, s.copyWith(isBookmarked: false));
    }
    _load();
  }

  List<Summary> get bookmarked =>
      state.where((s) => s.isBookmarked).toList();

  List<Summary> search(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state.where((s) =>
        s.headline.toLowerCase().contains(q) ||
        s.originalText.toLowerCase().contains(q)).toList();
  }
}
