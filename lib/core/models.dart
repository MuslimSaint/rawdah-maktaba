/// Data models for the Rawdah Maktaba app.

// ─── Announcement ────────────────────────────────────────

class Announcement {
  final bool active;
  final String message;
  final String type;
  final String downloadUrl;
  final String minVersionToShow;
  final String maxVersionToShow;

  const Announcement({
    required this.active,
    required this.message,
    required this.type,
    this.downloadUrl = '',
    this.minVersionToShow = '',
    this.maxVersionToShow = '',
  });

  factory Announcement.fromJson(
      Map<String, dynamic> json) {
    return Announcement(
      active: json['active'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      downloadUrl:
          json['downloadUrl'] as String? ?? '',
      minVersionToShow:
          json['minVersionToShow'] as String? ?? '',
      maxVersionToShow:
          json['maxVersionToShow'] as String? ?? '',
    );
  }

  bool get isUpdate => type == 'update';
  bool get hasDownloadUrl => downloadUrl.isNotEmpty;
}

// ─── Teacher ─────────────────────────────────────────────

class Teacher {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameAm;
  final String initials;
  final String photoUrl;

  const Teacher({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameAm,
    required this.initials,
    this.photoUrl = '',
  });

  factory Teacher.fromJson(
      Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      nameAm:
          (json['nameAm'] as String?)?.isNotEmpty ==
                  true
              ? json['nameAm'] as String
              : json['nameEn'] as String,
      initials: json['initials'] as String,
      photoUrl:
          json['photoUrl'] as String? ?? '',
    );
  }

  bool get hasPhoto => photoUrl.isNotEmpty;

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

// ─── Reciter ─────────────────────────────────────────────

class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameAm;
  final String initials;
  final String photoUrl;

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameAm,
    required this.initials,
    this.photoUrl = '',
  });

  factory Reciter.fromJson(
      Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      nameAm:
          (json['nameAm'] as String?)?.isNotEmpty ==
                  true
              ? json['nameAm'] as String
              : json['nameEn'] as String,
      initials: json['initials'] as String,
      photoUrl:
          json['photoUrl'] as String? ?? '',
    );
  }

  bool get hasPhoto => photoUrl.isNotEmpty;

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
  final Map<int, String> urls;
  final Map<int, String> partNames;

  const TeacherAudio({
    required this.teacherId,
    required this.parts,
    this.urls = const {},
    this.partNames = const {},
  });

  factory TeacherAudio.fromJson(
      Map<String, dynamic> json) {
    final urlsRaw =
        json['urls'] as Map<String, dynamic>? ?? {};
    final urls = <int, String>{};
    urlsRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null &&
          value is String &&
          value.isNotEmpty) {
        urls[n] = value;
      }
    });

    final partNamesRaw =
        json['partNames'] as Map<String, dynamic>? ?? {};
    final partNames = <int, String>{};
    partNamesRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null &&
          value is String &&
          value.isNotEmpty) {
        partNames[n] = value;
      }
    });

    return TeacherAudio(
      teacherId: json['teacherId'] as String,
      parts: (json['parts'] as List)
          .map((p) => p as int)
          .toList(),
      urls: urls,
      partNames: partNames,
    );
  }

  int get totalParts => parts.length;
  bool hasPart(int partNumber) =>
      parts.contains(partNumber);
  int indexOf(int partNumber) =>
      parts.indexOf(partNumber);
  String? urlForPart(int partNumber) =>
      urls[partNumber];

  String nameForPart(int partNumber) {
    final custom = partNames[partNumber];
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return _arabicOrdinal(partNumber);
  }

  static String _arabicOrdinal(int n) {
    const ordinals = [
      '',
      'الجزء الأول',
      'الجزء الثاني',
      'الجزء الثالث',
      'الجزء الرابع',
      'الجزء الخامس',
      'الجزء السادس',
      'الجزء السابع',
      'الجزء الثامن',
      'الجزء التاسع',
      'الجزء العاشر',
      'الجزء الحادي عشر',
      'الجزء الثاني عشر',
      'الجزء الثالث عشر',
      'الجزء الرابع عشر',
      'الجزء الخامس عشر',
      'الجزء السادس عشر',
      'الجزء السابع عشر',
      'الجزء الثامن عشر',
      'الجزء التاسع عشر',
      'الجزء العشرون',
    ];
    if (n >= 1 && n < ordinals.length) {
      return ordinals[n];
    }
    return 'الجزء $n';
  }
}

// ─── ReciterAudio ────────────────────────────────────────

class ReciterAudio {
  final String reciterId;
  final List<int> parts;
  final Map<int, String> urls;
  final Map<int, String> partNames;

  const ReciterAudio({
    required this.reciterId,
    required this.parts,
    this.urls = const {},
    this.partNames = const {},
  });

  factory ReciterAudio.fromJson(
      Map<String, dynamic> json) {
    final urlsRaw =
        json['urls'] as Map<String, dynamic>? ?? {};
    final urls = <int, String>{};
    urlsRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null &&
          value is String &&
          value.isNotEmpty) {
        urls[n] = value;
      }
    });

    final partNamesRaw =
        json['partNames'] as Map<String, dynamic>? ?? {};
    final partNames = <int, String>{};
    partNamesRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null &&
          value is String &&
          value.isNotEmpty) {
        partNames[n] = value;
      }
    });

    return ReciterAudio(
      reciterId: json['reciterId'] as String,
      parts: (json['parts'] as List)
          .map((p) => p as int)
          .toList(),
      urls: urls,
      partNames: partNames,
    );
  }

  int get totalParts => parts.length;
  bool hasPart(int partNumber) =>
      parts.contains(partNumber);
  int indexOf(int partNumber) =>
      parts.indexOf(partNumber);
  String? urlForPart(int partNumber) =>
      urls[partNumber];

  String nameForPart(int partNumber) {
    final custom = partNames[partNumber];
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return TeacherAudio._arabicOrdinal(partNumber);
  }
}

// ─── ContentTableEntry ───────────────────────────────────
//
// Supports nested children for hierarchical TOCs.
//
// Format in JSON:
//   {
//     "titleAr": "كتاب الطهارة",
//     "titleEn": "",
//     "page": 5,
//     "children": [
//       {"titleAr": "باب المياه", "titleEn": "", "page": 6, "children": [...]},
//       {"titleAr": "باب التيمم", "titleEn": "", "page": 30}
//     ]
//   }
//
// - "children" is optional. Absent, null, or empty
//   list all mean the entry has no children.
// - Nesting depth is unlimited.
// - Old flat TOCs (no "children" field anywhere)
//   continue to work: every entry becomes a leaf.

class ContentTableEntry {
  final String titleAr;
  final String titleEn;
  final int page;
  final List<ContentTableEntry> children;

  const ContentTableEntry({
    required this.titleAr,
    required this.titleEn,
    required this.page,
    this.children = const [],
  });

  factory ContentTableEntry.fromJson(
      Map<String, dynamic> json) {
    final childrenRaw =
        json['children'] as List? ?? const [];
    final children = childrenRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => ContentTableEntry.fromJson(m))
        .where(
            (e) => e.titleAr.isNotEmpty && e.page >= 1)
        .toList();

    return ContentTableEntry(
      titleAr: json['titleAr'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      page: json['page'] as int? ?? 1,
      children: children,
    );
  }

  bool get hasEnglish => titleEn.isNotEmpty;
  bool get hasChildren => children.isNotEmpty;
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

  /// Embedded content table from the catalog.
  /// Used as fallback if contentTableUrl is absent
  /// or the remote file has not been downloaded yet.
  /// Supports nested children.
  final List<ContentTableEntry> contentTable;

  /// Optional URL to an external JSON file containing
  /// the content table. When present and the file has
  /// been downloaded, it takes priority over the
  /// embedded contentTable above.
  ///
  /// Format supports nested children:
  ///   [
  ///     {
  ///       "titleAr": "...",
  ///       "titleEn": "...",
  ///       "page": 1,
  ///       "children": [ ... ]
  ///     }
  ///   ]
  ///
  /// Local cache key: toc_<bookId>.json
  final String contentTableUrl;

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
    this.contentTable = const [],
    this.contentTableUrl = '',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final ctRaw =
        json['contentTable'] as List? ?? const [];
    final contentTable = ctRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => ContentTableEntry.fromJson(m))
        .where(
            (e) => e.titleAr.isNotEmpty && e.page >= 1)
        .toList();

    return Book(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      authorAr: json['authorAr'] as String,
      authorEn: json['authorEn'] as String,
      authorShort: json['authorShort'] as String,
      branches: List<String>.from(
          json['branches'] as List),
      pages: json['pages'] as int? ?? 0,
      pdfSizeMb:
          (json['pdfSizeMb'] as num?)?.toDouble() ??
              0.0,
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
      contentTable: contentTable,
      contentTableUrl:
          json['contentTableUrl'] as String? ?? '',
    );
  }

  bool get hasContentTable =>
      contentTable.isNotEmpty;
  bool get hasContentTableUrl =>
      contentTableUrl.isNotEmpty;

  /// True if either embedded or external content
  /// table data is available. PdfReaderScreen uses
  /// this to decide whether to show the button.
  /// It will check local cache for external first.
  bool get mayHaveContentTable =>
      hasContentTable || hasContentTableUrl;

  bool get isRecentlyAdded =>
      DateTime.now().difference(addedAt).inDays <= 7;
  bool isInBranch(String branchId) =>
      branches.contains(branchId);
  String get localCoverAsset =>
      'assets/covers/$id.jpg';
  List<String> get teacherIds =>
      teacherAudio.map((t) => t.teacherId).toList();

  TeacherAudio? audioForTeacher(String teacherId) {
    try {
      return teacherAudio.firstWhere(
          (t) => t.teacherId == teacherId);
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

class SurahMeta {
  final int number;
  final String nameAr;
  final String nameTransliteration;
  final int ayahCount;
  final String revelationPlace;
  final int revelationOrder;

  const SurahMeta({
    required this.number,
    required this.nameAr,
    required this.nameTransliteration,
    required this.ayahCount,
    required this.revelationPlace,
    required this.revelationOrder,
  });

  String get displayNameAr => nameAr;

  String? transliterationFor(String lang) {
    if (lang == 'ar') return null;
    return nameTransliteration;
  }
}

// ─── Surah ───────────────────────────────────────────────

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

  factory Surah.fromJson(
      int number, Map<String, dynamic> json) {
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

// ─── MushafExtra ─────────────────────────────────────────

class MushafExtra {
  final String titleAr;
  final int page;

  const MushafExtra({
    required this.titleAr,
    required this.page,
  });

  factory MushafExtra.fromJson(
      Map<String, dynamic> json) {
    return MushafExtra(
      titleAr: json['titleAr'] as String? ?? '',
      page: json['page'] as int? ?? 0,
    );
  }
}

// ─── MushafEdition ───────────────────────────────────────

class MushafEdition {
  final String id;
  final String titleAr;
  final String titleEn;
  final String titleAm;
  final String pdfUrl;
  final Map<int, int> surahPages;
  final List<MushafExtra> extras;

  const MushafEdition({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleAm,
    required this.pdfUrl,
    required this.surahPages,
    required this.extras,
  });

  factory MushafEdition.fromJson(
      Map<String, dynamic> json) {
    final surahPagesRaw =
        json['surahPages'] as Map<String, dynamic>? ??
            {};
    final surahPages = <int, int>{};
    surahPagesRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null && value is int) {
        surahPages[n] = value;
      }
    });

    final extrasRaw =
        json['extras'] as List? ?? const [];
    final extras = extrasRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => MushafExtra.fromJson(m))
        .toList();

    final titleAr =
        json['titleAr'] as String? ?? '';
    final titleEn =
        json['titleEn'] as String? ?? '';
    final titleAm =
        json['titleAm'] as String? ?? '';

    return MushafEdition(
      id: json['id'] as String,
      titleAr: titleAr,
      titleEn:
          titleEn.isNotEmpty ? titleEn : titleAr,
      titleAm:
          titleAm.isNotEmpty ? titleAm : titleEn,
      pdfUrl: json['pdfUrl'] as String? ?? '',
      surahPages: surahPages,
      extras: extras,
    );
  }

  String titleFor(String lang) {
    switch (lang) {
      case 'ar':
        return titleAr;
      case 'am':
        return titleAm.isNotEmpty ? titleAm : titleEn;
      default:
        return titleEn.isNotEmpty ? titleEn : titleAr;
    }
  }

  int? pageForSurah(int surahNumber) =>
      surahPages[surahNumber];
  bool get hasContentTable => surahPages.isNotEmpty;
  bool get hasPdf => pdfUrl.isNotEmpty;
}

// ─── QuranSubBranch ──────────────────────────────────────

enum QuranSubBranchType {
  mushaf,
  surahs,
  branch,
  unknown
}

class QuranSubBranch {
  final String id;
  final QuranSubBranchType type;
  final String titleAr;
  final String titleEn;
  final String titleAm;
  final List<MushafEdition> editions;
  final List<Book> books;

  const QuranSubBranch({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.titleAm,
    required this.editions,
    required this.books,
  });

  factory QuranSubBranch.fromJson(
      Map<String, dynamic> json) {
    final typeStr =
        (json['type'] as String? ?? '').toLowerCase();
    QuranSubBranchType type;
    switch (typeStr) {
      case 'mushaf':
        type = QuranSubBranchType.mushaf;
        break;
      case 'surahs':
        type = QuranSubBranchType.surahs;
        break;
      case 'branch':
        type = QuranSubBranchType.branch;
        break;
      default:
        type = QuranSubBranchType.unknown;
    }

    final titleAr =
        json['titleAr'] as String? ?? '';
    final titleEn =
        json['titleEn'] as String? ?? '';
    final titleAmRaw =
        json['titleAm'] as String? ?? '';

    List<MushafEdition> editions = const [];
    if (type == QuranSubBranchType.mushaf) {
      final editionsRaw = json['editions'] as List?;
      if (editionsRaw != null &&
          editionsRaw.isNotEmpty) {
        editions = editionsRaw
            .whereType<Map<String, dynamic>>()
            .map((m) => MushafEdition.fromJson(m))
            .where(
                (e) => e.hasPdf || e.hasContentTable)
            .toList();
      } else {
        final legacyPdfUrl =
            json['pdfUrl'] as String? ?? '';
        final legacySurahPagesRaw =
            json['surahPages']
                as Map<String, dynamic>? ??
            {};
        final legacySurahPages = <int, int>{};
        legacySurahPagesRaw.forEach((key, value) {
          final n = int.tryParse(key);
          if (n != null && value is int) {
            legacySurahPages[n] = value;
          }
        });
        final legacyExtrasRaw =
            json['extras'] as List? ?? const [];
        final legacyExtras = legacyExtrasRaw
            .whereType<Map<String, dynamic>>()
            .map((m) => MushafExtra.fromJson(m))
            .toList();

        if (legacyPdfUrl.isNotEmpty ||
            legacySurahPages.isNotEmpty) {
          editions = [
            MushafEdition(
              id: json['id'] as String,
              titleAr: titleAr,
              titleEn: titleEn.isNotEmpty
                  ? titleEn
                  : titleAr,
              titleAm: titleAmRaw.isNotEmpty
                  ? titleAmRaw
                  : titleEn,
              pdfUrl: legacyPdfUrl,
              surahPages: legacySurahPages,
              extras: legacyExtras,
            ),
          ];
        }
      }
    }

    final books = json['books'] != null
        ? (json['books'] as List)
            .map((b) => Book.fromJson(
                b as Map<String, dynamic>))
            .toList()
        : const <Book>[];

    return QuranSubBranch(
      id: json['id'] as String,
      type: type,
      titleAr: titleAr,
      titleEn:
          titleEn.isNotEmpty ? titleEn : titleAr,
      titleAm: titleAmRaw.isNotEmpty
          ? titleAmRaw
          : titleEn,
      editions: editions,
      books: books,
    );
  }

  String titleFor(String lang) {
    switch (lang) {
      case 'ar':
        return titleAr;
      case 'am':
        return titleAm.isNotEmpty ? titleAm : titleEn;
      default:
        return titleEn.isNotEmpty ? titleEn : titleAr;
    }
  }

  bool get hasEditions => editions.isNotEmpty;
}

// ─── QuranData ───────────────────────────────────────────

class QuranData {
  final String mushafPdfUrl;
  final Map<int, Surah> surahs;
  final List<QuranSubBranch> subBranches;

  const QuranData({
    required this.mushafPdfUrl,
    required this.surahs,
    required this.subBranches,
  });

  factory QuranData.fromJson(
      Map<String, dynamic> json) {
    final surahsRaw =
        json['surahs'] as Map<String, dynamic>? ??
            {};
    final surahs = <int, Surah>{};
    surahsRaw.forEach((key, value) {
      final n = int.tryParse(key);
      if (n != null &&
          value is Map<String, dynamic>) {
        surahs[n] = Surah.fromJson(n, value);
      }
    });

    final subBranchesRaw =
        json['subBranches'] as List? ?? const [];
    final subBranches = subBranchesRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => QuranSubBranch.fromJson(m))
        .where((sb) =>
            sb.type != QuranSubBranchType.unknown)
        .toList();

    return QuranData(
      mushafPdfUrl:
          json['mushafPdfUrl'] as String? ?? '',
      surahs: surahs,
      subBranches: subBranches,
    );
  }

  factory QuranData.empty() {
    return const QuranData(
      mushafPdfUrl: '',
      surahs: {},
      subBranches: [],
    );
  }

  bool get hasMushaf => mushafPdfUrl.isNotEmpty;

  Surah surahFor(int number) {
    return surahs[number] ?? Surah.empty(number);
  }
}

// ─── Settings models ─────────────────────────────────────

class SettingsLink {
  final String name;
  final String platform;
  final String handle;
  final String url;
  final String description;

  const SettingsLink({
    required this.name,
    required this.platform,
    required this.handle,
    required this.url,
    required this.description,
  });

  factory SettingsLink.fromJson(
      Map<String, dynamic> json) {
    return SettingsLink(
      name: json['name'] as String? ?? '',
      platform:
          (json['platform'] as String? ?? '')
              .toLowerCase(),
      handle: json['handle'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description:
          json['description'] as String? ?? '',
    );
  }
}

class FaqEntry {
  final String question;
  final String answer;

  const FaqEntry(
      {required this.question,
      required this.answer});

  factory FaqEntry.fromJson(
      Map<String, dynamic> json) {
    return FaqEntry(
      question:
          json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class PrivacyEntry {
  final String title;
  final String content;

  const PrivacyEntry(
      {required this.title,
      required this.content});

  factory PrivacyEntry.fromJson(
      Map<String, dynamic> json) {
    return PrivacyEntry(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class CreditEntry {
  final String nameAr;
  final String nameEn;
  final List<SettingsLink> links;

  const CreditEntry({
    required this.nameAr,
    required this.nameEn,
    required this.links,
  });

  factory CreditEntry.fromJson(
      Map<String, dynamic> json) {
    final linksRaw =
        json['links'] as List? ?? const [];
    return CreditEntry(
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      links: linksRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => SettingsLink.fromJson(m))
          .toList(),
    );
  }
}

class AppSettings {
  final List<SettingsLink> connectLinks;
  final List<FaqEntry> faq;
  final List<PrivacyEntry> privacy;
  final String aboutDescription;
  final List<CreditEntry> credits;

  const AppSettings({
    required this.connectLinks,
    required this.faq,
    required this.privacy,
    required this.aboutDescription,
    required this.credits,
  });

  factory AppSettings.fromJson(
      Map<String, dynamic> json) {
    final connectRaw =
        json['connectLinks'] as List? ?? const [];
    final faqRaw =
        json['faq'] as List? ?? const [];
    final privacyRaw =
        json['privacy'] as List? ?? const [];
    final creditsRaw =
        json['credits'] as List? ?? const [];

    return AppSettings(
      connectLinks: connectRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => SettingsLink.fromJson(m))
          .toList(),
      faq: faqRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => FaqEntry.fromJson(m))
          .toList(),
      privacy: privacyRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => PrivacyEntry.fromJson(m))
          .toList(),
      aboutDescription:
          json['aboutDescription'] as String? ?? '',
      credits: creditsRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => CreditEntry.fromJson(m))
          .toList(),
    );
  }

  factory AppSettings.defaults() {
    return const AppSettings(
      connectLinks: [],
      faq: [],
      privacy: [],
      aboutDescription: '',
      credits: [],
    );
  }

  bool get hasConnectLinks => connectLinks.isNotEmpty;
  bool get hasFaq => faq.isNotEmpty;
  bool get hasPrivacy => privacy.isNotEmpty;
  bool get hasCredits => credits.isNotEmpty;
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
  final AppSettings settings;

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
    AppSettings? settings,
  }) : settings = settings ??
            const AppSettings(
              connectLinks: [],
              faq: [],
              privacy: [],
              aboutDescription: '',
              credits: [],
            );

  factory Catalog.fromJson(
      Map<String, dynamic> json) {
    return Catalog(
      books: (json['books'] as List)
          .map((b) => Book.fromJson(
              b as Map<String, dynamic>))
          .toList(),
      teachers: (json['teachers'] as List)
          .map((t) => Teacher.fromJson(
              t as Map<String, dynamic>))
          .toList(),
      reciters: json['reciters'] != null
          ? (json['reciters'] as List)
              .map((r) => Reciter.fromJson(
                  r as Map<String, dynamic>))
              .toList()
          : [],
      quran: json['quran'] != null
          ? QuranData.fromJson(
              json['quran'] as Map<String, dynamic>)
          : QuranData.empty(),
      version: json['version'] as String? ?? '1',
      minAppVersion:
          json['minAppVersion'] as String? ??
              '1.0.0',
      audioBaseUrl:
          json['audioBaseUrl'] as String? ??
              'https://github.com/MuslimSaint/rawdah-catalog/'
                  'releases/download/v1.0-books',
      quranBaseUrl:
          json['quranBaseUrl'] as String? ??
              'https://github.com/MuslimSaint/rawdah-catalog/'
                  'releases/download/v1.0-quran',
      announcement: json['announcement'] != null
          ? Announcement.fromJson(
              json['announcement']
                  as Map<String, dynamic>)
          : null,
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings']
              as Map<String, dynamic>)
          : AppSettings.defaults(),
    );
  }

  static Map<String, dynamic> assembleJson({
    required Map<String, dynamic> root,
    required Map<String, dynamic> teachers,
    required Map<String, dynamic> reciters,
    required Map<String, dynamic> books,
    required Map<String, dynamic> surahs,
    required Map<String, dynamic> mushaf,
  }) {
    final teachersList =
        _asList(teachers['teachers']);
    final recitersList =
        _asList(reciters['reciters']);
    final booksList = _asList(books['books']);

    Map<String, dynamic> surahMap;
    if (surahs.containsKey('surahs')) {
      surahMap = _asMap(surahs['surahs']);
    } else if (surahs.containsKey('quran')) {
      surahMap = _asMap(
          (_asMap(surahs['quran']))['surahs']);
    } else {
      surahMap = {};
    }

    Map<String, dynamic> mushafContent;
    if (mushaf.containsKey('subBranches')) {
      mushafContent = mushaf;
    } else if (mushaf.containsKey('quran')) {
      mushafContent = _asMap(mushaf['quran']);
    } else {
      mushafContent = mushaf;
    }

    final mushafPdfUrl =
        mushafContent['mushafPdfUrl'] as String? ??
            '';
    final subBranches =
        _asList(mushafContent['subBranches']);

    return {
      'version':
          root['version']?.toString() ?? '1',
      'minAppVersion':
          root['minAppVersion']?.toString() ??
              '1.0.0',
      'audioBaseUrl':
          root['audioBaseUrl'] as String? ??
              'https://github.com/MuslimSaint/rawdah-catalog/'
                  'releases/download/v1.0-books',
      'quranBaseUrl':
          root['quranBaseUrl'] as String? ??
              'https://github.com/MuslimSaint/rawdah-catalog/'
                  'releases/download/v1.0-quran',
      'announcement': root['announcement'] ??
          {
            'active': false,
            'message': '',
            'type': 'info',
          },
      if (root['settings'] != null)
        'settings': root['settings'],
      'teachers': teachersList,
      'reciters': recitersList,
      'books': booksList,
      'quran': {
        'mushafPdfUrl': mushafPdfUrl,
        'surahs': surahMap,
        'subBranches': subBranches,
      },
    };
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return <dynamic>[];
  }

  static Map<String, dynamic> _asMap(
      dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value
          .map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
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
      books
          .where((b) => b.isInBranch(branchId))
          .toList();

  List<Book> search(String query) {
    if (query.trim().isEmpty) return books;
    final q = query.trim().toLowerCase();
    return books.where((b) {
      return b.titleAr.contains(q) ||
          b.authorAr.toLowerCase().contains(q) ||
          b.authorEn.toLowerCase().contains(q);
    }).toList();
  }

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
      nameAm: 'ዐቂዳ',
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
