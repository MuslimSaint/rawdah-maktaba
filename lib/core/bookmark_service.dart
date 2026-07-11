import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single bookmark (tagged page) in the Mus'haf.
class MushafBookmark {
  final int page;
  final String name;
  final DateTime addedAt;

  const MushafBookmark({
    required this.page,
    required this.name,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'name': name,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MushafBookmark.fromJson(Map<String, dynamic> json) {
    return MushafBookmark(
      page: json['page'] as int,
      name: json['name'] as String? ?? 'Page ${json['page']}',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Manages local bookmarks for the Full Mus'haf.
/// Stored in SharedPreferences — local only, no Firebase.
class BookmarkService extends ChangeNotifier {
  static const _key = 'mushaf_bookmarks';

  final List<MushafBookmark> _bookmarks = [];

  List<MushafBookmark> get bookmarks =>
      List.unmodifiable(_bookmarks);

  int get count => _bookmarks.length;

  bool isBookmarked(int page) =>
      _bookmarks.any((b) => b.page == page);

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _bookmarks.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _bookmarks.add(MushafBookmark.fromJson(item));
          }
        }
        // Sort by page number
        _bookmarks.sort((a, b) => a.page.compareTo(b.page));
      }
    } catch (_) {}
  }

  // ─── Add ───────────────────────────────────────────

  Future<void> addBookmark({
    required int page,
    required String name,
  }) async {
    // Don't add duplicate pages
    if (isBookmarked(page)) return;

    _bookmarks.add(MushafBookmark(
      page: page,
      name: name.isEmpty ? 'Page ${page + 1}' : name,
      addedAt: DateTime.now(),
    ));

    _bookmarks.sort((a, b) => a.page.compareTo(b.page));
    await _save();
    notifyListeners();
  }

  // ─── Remove ────────────────────────────────────────

  Future<void> removeBookmark(int page) async {
    _bookmarks.removeWhere((b) => b.page == page);
    await _save();
    notifyListeners();
  }

  // ─── Rename ────────────────────────────────────────

  Future<void> renameBookmark(int page, String newName) async {
    final index =
        _bookmarks.indexWhere((b) => b.page == page);
    if (index < 0) return;

    final old = _bookmarks[index];
    _bookmarks[index] = MushafBookmark(
      page: old.page,
      name: newName.isEmpty ? 'Page ${page + 1}' : newName,
      addedAt: old.addedAt,
    );
    await _save();
    notifyListeners();
  }

  // ─── Clear all ─────────────────────────────────────

  Future<void> clearAll() async {
    _bookmarks.clear();
    await _save();
    notifyListeners();
  }

  // ─── Persistence ───────────────────────────────────

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {}
  }
}
