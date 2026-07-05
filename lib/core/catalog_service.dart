import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
class CatalogService extends ChangeNotifier {
  static const _cacheKey = 'catalog_json';
  static const _catalogUrl =
      'https://raw.githubusercontent.com/MuslimSaint/rawdah-catalog/main/catalog.json';

  Catalog? _catalog;
  bool _isLoading = false;
  String? _error;

  Catalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _catalog != null;

  // ─── Catalog data ──────────────────────────────────

  List<Book> get books => _catalog?.books ?? [];
  List<Teacher> get teachers => _catalog?.teachers ?? [];
  String get audioBaseUrl =>
      _catalog?.audioBaseUrl ??
      'https://github.com/MuslimSaint/rawdah-catalog/releases/download/v1.0-books';

  /// Active announcement to show as banner, or null.
  Announcement? get activeAnnouncement {
    final a = _catalog?.announcement;
    if (a == null || !a.active || a.message.isEmpty) {
      return null;
    }
    return a;
  }

  // ─── Load ────────────────────────────────────────────

  Future<void> load() async {
    await _loadFromCache();
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        _catalog = Catalog.fromJson(json);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _fetchFromNetwork() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse(_catalogUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>;
        _catalog = Catalog.fromJson(json);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, response.body);
        _error = null;
      } else {
        _error =
            'Failed to load catalog (${response.statusCode})';
      }
    } catch (e) {
      if (_catalog == null) {
        _error =
            'No internet connection and no cached data.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _fetchFromNetwork();
  }

  // ─── Helpers ─────────────────────────────────────────

  List<Book> booksInBranch(String branchId) =>
      _catalog?.booksInBranch(branchId) ?? [];

  List<Book> search(String query) =>
      _catalog?.search(query) ?? [];

  Teacher? teacherById(String id) =>
      _catalog?.teacherById(id);

  int bookCountForBranch(String branchId) =>
      booksInBranch(branchId).length;

  /// Constructs the audio URL for a specific part.
  /// Uses audioBaseUrl from catalog — no hardcoding.
  String audioUrl({
    required String bookId,
    required String teacherId,
    required int partNumber,
  }) {
    return '$audioBaseUrl/${bookId}_${teacherId}_$partNumber.mp3';
  }
}
