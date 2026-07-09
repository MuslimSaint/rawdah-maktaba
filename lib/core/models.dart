/// Data models for the Rawdah Maktaba app.

// ─── Announcement ────────────────────────────────────────

class Announcement {
  final bool active;
  final String message;
  final String type;

  const Announcement({
    required this.active,
    required this.message,
    required this.type,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      active: json['active'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
    );
  }
}

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

// ─── Reciter ────────────────────────────────────────────
// Reciters (Qaris) recite the Quran beautifully.
// Different from Teachers — teachers explain/tafseer.
// Both can appear on a Surah's detail screen.

class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameAm;
  final String initials;

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameAm,
    required this.initials,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      nameAm: (json['nameAm'] as String?)?.isNotEmpty == true
          ? json['nameAm'] as String
          : json['nameEn'] as String,
      initials: json['initials'] as String,
    );
  }

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

class TeacherAudio {
  final String teacherId;
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

  int get totalParts => parts.length;
  bool hasPart(int partNumber) => parts.contains(partNumber);
  int indexOf(int partNumber) => parts.indexOf(partNumber);
}

// ─── ReciterAudio ────────────────────────────────────────
// A Reciter's recording(s) for a specific Surah.
// Each Reciter has independent parts, like TeacherAudio.

class ReciterAudio {
  final String reciterId;
  final List<int> parts;

  const ReciterAudio({
    required this.reciterId,
    required this.parts,
  });

  factory ReciterAudio.fromJson(Map<String, dynamic> json) {
    return ReciterAudio(
      reciterId: json['reciterId'] as String,
      parts: (json['parts'] as List)
          .map((p) => p as int)
          .toList(),
    );
  }

  int get totalParts => parts.length;
  bool hasPart(int partNumber) => parts.contains(partNumber);
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
      pages: json['pages'] as int? ?? 0,
      pdfSizeMb:
          (json['pdfSizeMb'] as num?)?.toDouble() ?? 0.0,
      hasAudio: json['hasAudio'] as bool? ?? false,
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

  List<String> get teacherIds =>
      teacherAudio.map((t) => t.teacherId).toList();

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

// ─── SurahMeta ───────────────────────────────────────────
// Metadata about a single Surah.
// The 114 SurahMeta entries are hardcoded in quran_data.dart
// because Surahs are architectural (like branches), not content.

class SurahMeta {
  /// Surah number 1..114
  final int number;

  /// Arabic name (e.g. الفاتحة)
  final String nameAr;

  /// English transcription of the name (e.g. Al-Fatiha)
  final String nameTransliteration;

  /// English meaning (e.g. The Opening)
  final String meaningEn;

  /// Number of ayat
  final int ayahCount;

  /// 'meccan' or 'medinan'
  final String revelationPlace;

  /// Order of revelation (1..114)
  final int revelationOrder;

  const SurahMeta({
    required this.number,
    required this.nameAr,
    required this.nameTransliteration,
    required this.meaningEn,
    required this.ayahCount,
    required this.revelationPlace,
    required this.revelationOrder,
  });

  /// The name shown next to the number in the list.
  /// Arabic name for all languages.
  String get displayNameAr => nameAr;

  /// The transliteration shown when app language is en or am.
  /// Not shown when app language is ar.
  String? transliterationFor(String lang) {
    if (lang == 'ar') return null;
    return nameTransliteration;
  }
}

// ─── Surah (catalog part) ────────────────────────────────
// The remote/catalog data for a Surah — what's actually
// uploaded (PDF + reciters + teachers).
// Combined with SurahMeta at runtime.

class Surah {
  final int number;
  final String pdfUrl;
  final List<ReciterAudio> reciters;
  final List<TeacherAudio> teachers;

  const Surah({
    required this.number,
    required this.pdfUrl,
    required this.reciters,
    required this.teachers,
  });

  factory Surah.fromJson(int number, Map<String, dynamic> json) {
    return Surah(
      number: number,
      pdfUrl: json['pdfUrl'] as String? ?? '',
      reciters: json['reciters'] != null
          ? (json['reciters'] as List)
              .map((r) => ReciterAudio.fromJson(
                  r as Map<String, dynamic>))
              .toList()
          : [],
      teachers: json['teachers'] != null
          ? (json['teachers'] as List)
              .map((t) => TeacherAudio.fromJson(
                  t as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Empty placeholder Surah (nothing uploaded).
  factory Surah.empty(int number) {
    return Surah(
      number: number,
      pdfUrl: '',
      reciters: const [],
      teachers: const [],
    );
  }

  bool get hasPdf => pdfUrl.isNotEmpty;
  bool get hasReciters => reciters.isNotEmpty;
  bool get hasTeachers => teachers.isNotEmpty;
  bool get hasAnything =>
      hasPdf || hasReciters || hasTeachers;
}

// ─── QuranData (catalog part) ────────────────────────────

class QuranData {
  final String mushafPdfUrl;
  final Map<int, Surah> surahs;

  const QuranData({
    required this.mushafPdfUrl,
    required this.surahs,
  });

  factory QuranData.fromJson(Map<String, dynamic> json) {
    final surahsRaw =
        json['surahs'] as Map<String, dynamic>? ?? {};
    final surahs = <int, Surah>{};
    surahsRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null && value is Map<String, dynamic>) {
        surahs[n] = Surah.fromJson(n, value);
      }
    });
    return QuranData(
      mushafPdfUrl: json['mushafPdfUrl'] as String? ?? '',
      surahs: surahs,
    );
  }

  factory QuranData.empty() {
    return const QuranData(
      mushafPdfUrl: '',
      surahs: {},
    );
  }

  bool get hasMushaf => mushafPdfUrl.isNotEmpty;

  /// Returns the Surah data for a given number, or an
  /// empty Surah if not in catalog.
  Surah surahFor(int number) {
    return surahs[number] ?? Surah.empty(number);
  }
}

// ─── Catalog ─────────────────────────────────────────────

class Catalog {
  final List<Book> books;
  final List<Teacher> teachers;
  final List<Reciter> reciters;
  final QuranData quran;
  final String version;
  final String minAppVersion;
  final String audioBaseUrl;
  final String quranBaseUrl;
  final Announcement? announcement;

  const Catalog({
    required this.books,
    required this.teachers,
    required this.reciters,
    required this.quran,
    required this.version,
    required this.minAppVersion,
    required this.audioBaseUrl,
    required this.quranBaseUrl,
    this.announcement,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      books: (json['books'] as List)
          .map((b) => Book.fromJson(b as Map<String, dynamic>))
          .toList(),
      teachers: (json['teachers'] as List)
          .map((t) => Teacher.fromJson(t as Map<String, dynamic>))
          .toList(),
      reciters: json['reciters'] != null
          ? (json['reciters'] as List)
              .map((r) =>
                  Reciter.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
      quran: json['quran'] != null
          ? QuranData.fromJson(
              json['quran'] as Map<String, dynamic>)
          : QuranData.empty(),
      version: json['version'] as String? ?? '1',
      minAppVersion:
          json['minAppVersion'] as String? ?? '1.0.0',
      audioBaseUrl: json['audioBaseUrl'] as String? ??
          'https://github.com/MuslimSaint/rawdah-catalog/releases/download/v1.0-books',
      quranBaseUrl: json['quranBaseUrl'] as String? ??
          'https://github.com/MuslimSaint/rawdah-catalog/releases/download/v1.0-quran',
      announcement: json['announcement'] != null
          ? Announcement.fromJson(
              json['announcement'] as Map<String, dynamic>)
          : null,
    );
  }

  Teacher? teacherById(String id) {
    try {
      return teachers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Reciter? reciterById(String id) {
    try {
      return reciters.firstWhere((r) => r.id == id);
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
  // Tafseer removed. Quran added at position 1.
  // Arabic renamed to Arabic & Tajweed.
  static const List<Branch> branches = [
    Branch(
      id: 'quran',
      nameEn: 'The Noble Quran',
      nameAr: 'القرآن الكريم',
      nameAm: 'ቅዱስ ቁርኣን',
    ),
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
      id: 'arabic',
      nameEn: 'Arabic & Tajweed',
      nameAr: 'اللغة العربية والتجويد',
      nameAm: 'አረብኛ እና ተጅዊድ',
    ),
    Branch(
      id: 'seerah',
      nameEn: 'Seerah',
      nameAr: 'سيرة',
      nameAm: 'ሲራ',
    ),
  ];
}
