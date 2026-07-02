/// Data models for the Rawdah Maktaba app.
/// Book, Teacher, and Branch — all immutable, all JSON-deserializable.

// ─── Teacher ────────────────────────────────────────────

class Teacher {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameAm;
  final String initials;

  const Teacher({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameAm,
    required this.initials,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      nameAm: (json['nameAm'] as String?) ?? json['nameEn'] as String,
      initials: json['initials'] as String,
    );
  }

  /// Returns the teacher's name in the given language.
  /// Falls back to English if Amharic is not available.
  String nameFor(String lang) {
    switch (lang) {
      case 'ar':
        return nameAr;
      case 'am':
        return nameAm.isNotEmpty ? nameAm : nameEn;
      default:
        return nameEn;
    }
  }
}

// ─── Book ────────────────────────────────────────────────

class Book {
  final String id;
  final String titleAr;
  final String authorAr;
  final String authorEn;
  final String authorShort;
  final List<String> branches;
  final int pages;
  final double pdfSizeMb;
  final bool hasAudio;
  final List<String> teacherIds;
  final bool isNew;
  final int audioParts;
  final String pdfUrl;
  final String? coverUrl; // null = use bundled asset
  final DateTime addedAt;

  const Book({
    required this.id,
    required this.titleAr,
    required this.authorAr,
    required this.authorEn,
    required this.authorShort,
    required this.branches,
    required this.pages,
    required this.pdfSizeMb,
    required this.hasAudio,
    required this.teacherIds,
    required this.isNew,
    required this.audioParts,
    required this.pdfUrl,
    this.coverUrl,
    required this.addedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      authorAr: json['authorAr'] as String,
      authorEn: json['authorEn'] as String,
      authorShort: json['authorShort'] as String,
      branches: List<String>.from(json['branches'] as List),
      pages: json['pages'] as int,
      pdfSizeMb: (json['pdfSizeMb'] as num).toDouble(),
      hasAudio: json['hasAudio'] as bool,
      teacherIds: List<String>.from(json['teacherIds'] as List),
      isNew: json['isNew'] as bool? ?? false,
      audioParts: json['audioParts'] as int? ?? 0,
      pdfUrl: json['pdfUrl'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns true if the book was added within the last 7 days.
  bool get isRecentlyAdded {
    return DateTime.now().difference(addedAt).inDays <= 7;
  }

  /// Returns true if this book belongs to the given branch.
  bool isInBranch(String branchId) {
    return branches.contains(branchId);
  }

  /// Local asset path for bundled cover image.
  String get localCoverAsset => 'assets/covers/$id.jpg';
}

// ─── Branch ──────────────────────────────────────────────

class Branch {
  final String id;
  final String nameEn;
  final String nameAr;
  final String nameAm;

  const Branch({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.nameAm,
  });

  /// Returns the branch name in the given language.
  String nameFor(String lang) {
    switch (lang) {
      case 'ar':
        return nameAr;
      case 'am':
        return nameAm;
      default:
        return nameEn;
    }
  }
}

// ─── Catalog ─────────────────────────────────────────────

/// The full app catalog — all books and all teachers.
class Catalog {
  final List<Book> books;
  final List<Teacher> teachers;
  final String version;

  const Catalog({
    required this.books,
    required this.teachers,
    required this.version,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      books: (json['books'] as List)
          .map((b) => Book.fromJson(b as Map<String, dynamic>))
          .toList(),
      teachers: (json['teachers'] as List)
          .map((t) => Teacher.fromJson(t as Map<String, dynamic>))
          .toList(),
      version: json['version'] as String? ?? '1',
    );
  }

  /// Find a teacher by ID.
  Teacher? teacherById(String id) {
    try {
      return teachers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all books in a branch.
  List<Book> booksInBranch(String branchId) {
    return books.where((b) => b.isInBranch(branchId)).toList();
  }

  /// Search books by title or author.
  List<Book> search(String query) {
    if (query.trim().isEmpty) return books;
    final q = query.trim().toLowerCase();
    return books.where((b) {
      return b.titleAr.contains(q) ||
          b.authorAr.toLowerCase().contains(q) ||
          b.authorEn.toLowerCase().contains(q);
    }).toList();
  }

  /// The 6 fixed branches — always shown, always in this order.
  static const List<Branch> branches = [
    Branch(
      id: 'hadith',
      nameEn: 'Hadith',
      nameAr: 'حديث',
      nameAm: 'ሐዲስ',
    ),
    Branch(
      id: 'aqeedah',
      nameEn: 'Aqeedah',
      nameAr: 'عقيدة',
      nameAm: 'አቂዳ',
    ),
    Branch(
      id: 'fiqh',
      nameEn: 'Fiqh',
      nameAr: 'فقه',
      nameAm: 'ፊቅህ',
    ),
    Branch(
      id: 'seerah',
      nameEn: 'Seerah',
      nameAr: 'سيرة',
      nameAm: 'ሲራ',
    ),
    Branch(
      id: 'tafseer',
      nameEn: 'Tafseer',
      nameAr: 'تفسير',
      nameAm: 'ተፍሲር',
    ),
    Branch(
      id: 'arabic',
      nameEn: 'Arabic Language',
      nameAr: 'اللغة العربية',
      nameAm: 'አረብኛ ቋንቋ',
    ),
  ];
}
