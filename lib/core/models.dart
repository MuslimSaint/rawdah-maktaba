/// Data models for the Rawdah Maktaba app.
/// No teacher names, book titles, or content
/// is hardcoded here — everything comes from catalog.json.

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
      nameAm: (json['nameAm'] as String?)?.isNotEmpty == true
          ? json['nameAm'] as String
          : json['nameEn'] as String,
      initials: json['initials'] as String,
    );
  }

  /// Returns name in the requested language.
  /// Falls back to English if translation not available.
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

// ─── TeacherAudio ────────────────────────────────────────
// Represents ONE teacher's audio for ONE specific book.
// Completely independent per teacher — different teachers
// of the same book can have entirely different part counts,
// different missing episodes, different total lengths.
// There is NO maximum part number.

class TeacherAudio {
  final String teacherId;

  /// The actual part numbers this teacher has recorded.
  /// Example: [1,2,3,4,5,6,7,9,10] — episode 8 is missing.
  /// Can contain any positive integers, no maximum.
  /// Order matters — displayed in this exact order.
  final List<int> parts;

  const TeacherAudio({
    required this.teacherId,
    required this.parts,
  });

  factory TeacherAudio.fromJson(Map<String, dynamic> json) {
    return TeacherAudio(
      teacherId: json['teacherId'] as String,
      parts: (json['parts'] as List)
          .map((p) => p as int)
          .toList(),
    );
  }

  /// Total number of parts this teacher has recorded.
  /// Has no maximum — could be 5 or 500.
  int get totalParts => parts.length;

  /// Whether a specific part number exists for this teacher.
  bool hasPart(int partNumber) => parts.contains(partNumber);

  /// Returns the index of a part number in the parts list.
  /// Returns -1 if not found.
  int indexOf(int partNumber) => parts.indexOf(partNumber);
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

  /// Per-teacher audio. Each teacher is completely independent.
  /// One teacher may have 12 parts, another may have 500.
  /// A teacher can teach multiple books — each with
  /// their own independent part list for that book.
  final List<TeacherAudio> teacherAudio;

  final bool isNew;
  final String pdfUrl;
  final String? coverUrl;
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
    required this.teacherAudio,
    required this.isNew,
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
      teacherAudio: json['teacherAudio'] != null
          ? (json['teacherAudio'] as List)
              .map((t) => TeacherAudio.fromJson(
                  t as Map<String, dynamic>))
              .toList()
          : [],
      isNew: json['isNew'] as bool? ?? false,
      pdfUrl: json['pdfUrl'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isRecentlyAdded =>
      DateTime.now().difference(addedAt).inDays <= 7;

  bool isInBranch(String branchId) =>
      branches.contains(branchId);

  String get localCoverAsset => 'assets/covers/$id.jpg';

  /// All teacher IDs that have audio for this book.
  /// Comes entirely from catalog — never hardcoded.
  List<String> get teacherIds =>
      teacherAudio.map((t) => t.teacherId).toList();

  /// Get TeacherAudio for a specific teacher ID.
  /// Returns null if this teacher has no audio for this book.
  TeacherAudio? audioForTeacher(String teacherId) {
    try {
      return teacherAudio
          .firstWhere((t) => t.teacherId == teacherId);
    } catch (_) {
      return null;
    }
  }
}

// ─── Branch ──────────────────────────────────────────────
// Branches ARE fixed by design — there are exactly 6
// Islamic knowledge branches. These do not change.
// Branch ICONS are chosen in the UI layer, not here.

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

  /// Find teacher by ID — comes from catalog, never hardcoded.
  Teacher? teacherById(String id) {
    try {
      return teachers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Book> booksInBranch(String branchId) =>
      books.where((b) => b.isInBranch(branchId)).toList();

  List<Book> search(String query) {
    if (query.trim().isEmpty) return books;
    final q = query.trim().toLowerCase();
    return books.where((b) {
      return b.titleAr.contains(q) ||
          b.authorAr.toLowerCase().contains(q) ||
          b.authorEn.toLowerCase().contains(q);
    }).toList();
  }

  // ─── The 6 fixed branches ─────────────────────────────
  // These are the Islamic knowledge classification system.
  // They are architectural constants, not content data.
  // Branch NAMES come from here.
  // Branch ICONS are assigned in the UI (home_tab.dart).
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
