import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
/// Fetches from GitHub when online, falls back to cache when offline.
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

  // ─── Load ────────────────────────────────────────────

  /// Loads the catalog.
  /// First shows cached version immediately (if available),
  /// then fetches fresh version from GitHub in background.
  Future<void> load() async {
    // Step 1: Load from cache immediately (instant, no wait)
    await _loadFromCache();

    // Step 2: Fetch fresh version from network in background
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
    } catch (_) {
      // Cache corrupted — ignore, network will fix it
    }
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
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _catalog = Catalog.fromJson(json);

        // Cache the fresh version
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, response.body);

        _error = null;
      } else {
        _error = 'Failed to load catalog (${response.statusCode})';
      }
    } catch (e) {
      // Network error — use cache if available
      if (_catalog == null) {
        _error = 'No internet connection and no cached data available.';
      }
      // If we have cache, silently ignore network error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh from network.
  Future<void> refresh() async {
    await _fetchFromNetwork();
  }

  // ─── Helpers ─────────────────────────────────────────

  /// All books in the catalog.
  List<Book> get books => _catalog?.books ?? [];

  /// All teachers in the catalog.
  List<Teacher> get teachers => _catalog?.teachers ?? [];

  /// Books in a specific branch.
  List<Book> booksInBranch(String branchId) {
    return _catalog?.booksInBranch(branchId) ?? [];
  }

  /// Search books.
  List<Book> search(String query) {
    return _catalog?.search(query) ?? [];
  }

  /// Find teacher by ID.
  Teacher? teacherById(String id) {
    return _catalog?.teacherById(id);
  }

  /// Book count for a branch (used in Home tab grid).
  int bookCountForBranch(String branchId) {
    return booksInBranch(branchId).length;
  }
}
