import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single bookmark (tagged page) in any PDF.
class PdfBookmark {
  final int page;
  final String name;
  final DateTime addedAt;

  const PdfBookmark({
    required this.page,
    required this.name,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'name': name,
        'addedAt': addedAt.toIso8601String(),
      };

  factory PdfBookmark.fromJson(Map<String, dynamic> json) {
    return PdfBookmark(
      page: json['page'] as int,
      name: json['name'] as String? ?? 'Page ${json['page']}',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Manages local bookmarks for ANY PDF in the app.
/// Each PDF is identified by a unique key (e.g., book ID,
/// "mushaf", "surah_1", etc.).
/// Stored in SharedPreferences — local only, no Firebase.
class BookmarkService extends ChangeNotifier {
  static const _prefix = 'bookmarks_';

  // In-memory cache: pdfKey → list of bookmarks
  final Map<String, List<PdfBookmark>> _cache = {};

  // Currently active PDF key
  String? _activePdfKey;

  // ─── Active PDF ────────────────────────────────────

  /// Sets the active PDF whose bookmarks we're managing.
  /// Call this when opening a PDF reader.
  Future<void> setActivePdf(String pdfKey) async {
    _activePdfKey = pdfKey;
    if (!_cache.containsKey(pdfKey)) {
      await _loadForKey(pdfKey);
    }
    notifyListeners();
  }

  String? get activePdfKey => _activePdfKey;

  /// Returns bookmarks for the currently active PDF.
  List<PdfBookmark> get bookmarks {
    if (_activePdfKey == null) return const [];
    return List.unmodifiable(
        _cache[_activePdfKey!] ?? const []);
  }

  int get count {
    if (_activePdfKey == null) return 0;
    return _cache[_activePdfKey!]?.length ?? 0;
  }

  bool isBookmarked(int page) {
    if (_activePdfKey == null) return false;
    final list = _cache[_activePdfKey!];
    if (list == null) return false;
    return list.any((b) => b.page == page);
  }

  // ─── Load ──────────────────────────────────────────

  Future<void> _loadForKey(String pdfKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$pdfKey');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        final bookmarks = <PdfBookmark>[];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            bookmarks.add(PdfBookmark.fromJson(item));
          }
        }
        bookmarks.sort((a, b) => a.page.compareTo(b.page));
        _cache[pdfKey] = bookmarks;
      } else {
        _cache[pdfKey] = [];
      }
    } catch (_) {
      _cache[pdfKey] = [];
    }
  }

  /// Legacy init for backward compatibility.
  /// Loads Mus'haf bookmarks if they exist under old key.
  Future<void> init() async {
    // Migrate old 'mushaf_bookmarks' key if exists
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldKey = 'mushaf_bookmarks';
      final oldRaw = prefs.getString(oldKey);
      if (oldRaw != null &&
          !prefs.containsKey('${_prefix}mushaf')) {
        // Migrate to new key format
        await prefs.setString('${_prefix}mushaf', oldRaw);
        await prefs.remove(oldKey);
      }
    } catch (_) {}
  }

  // ─── Add ───────────────────────────────────────────

  Future<void> addBookmark({
    required int page,
    required String name,
    String? pdfKey,
  }) async {
    final key = pdfKey ?? _activePdfKey;
    if (key == null) return;

    final list = _cache[key] ?? [];
    if (list.any((b) => b.page == page)) return;

    list.add(PdfBookmark(
      page: page,
      name: name.isEmpty ? 'Page ${page + 1}' : name,
      addedAt: DateTime.now(),
    ));

    list.sort((a, b) => a.page.compareTo(b.page));
    _cache[key] = list;
    await _saveForKey(key);
    notifyListeners();
  }

  // ─── Remove ────────────────────────────────────────

  Future<void> removeBookmark(int page, {String? pdfKey}) async {
    final key = pdfKey ?? _activePdfKey;
    if (key == null) return;

    final list = _cache[key];
    if (list == null) return;

    list.removeWhere((b) => b.page == page);
    await _saveForKey(key);
    notifyListeners();
  }

  // ─── Rename ────────────────────────────────────────

  Future<void> renameBookmark(int page, String newName,
      {String? pdfKey}) async {
    final key = pdfKey ?? _activePdfKey;
    if (key == null) return;

    final list = _cache[key];
    if (list == null) return;

    final index = list.indexWhere((b) => b.page == page);
    if (index < 0) return;

    final old = list[index];
    list[index] = PdfBookmark(
      page: old.page,
      name: newName.isEmpty ? 'Page ${page + 1}' : newName,
      addedAt: old.addedAt,
    );
    await _saveForKey(key);
    notifyListeners();
  }

  // ─── Clear all for a specific PDF ──────────────────

  Future<void> clearAll({String? pdfKey}) async {
    final key = pdfKey ?? _activePdfKey;
    if (key == null) return;

    _cache[key] = [];
    await _saveForKey(key);
    notifyListeners();
  }

  // ─── Persistence ───────────────────────────────────

  Future<void> _saveForKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cache[key] ?? [];
      final json =
          jsonEncode(list.map((b) => b.toJson()).toList());
      await prefs.setString('$_prefix$key', json);
    } catch (_) {}
  }
}
