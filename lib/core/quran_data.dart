import 'models.dart';

/// Hardcoded skeleton of all 114 Surahs.
/// Like the 6 branches, this is architectural — never changes.
/// Only the PDF URLs and audio come from catalog.
///
/// Surah names are Arabic + English transcription only.
/// NO translation of the name is stored anywhere.
class QuranSkeleton {
  static const List<SurahMeta> surahs = [
    SurahMeta(number: 1, nameAr: 'الفاتحة', nameTransliteration: 'Al-Fatiha', ayahCount: 7, revelationPlace: 'meccan', revelationOrder: 5),
    SurahMeta(number: 2, nameAr: 'البقرة', nameTransliteration: 'Al-Baqara', ayahCount: 286, revelationPlace: 'medinan', revelationOrder: 87),
    SurahMeta(number: 3, nameAr: 'آل عمران', nameTransliteration: 'Aal Imran', ayahCount: 200, revelationPlace: 'medinan', revelationOrder: 89),
    SurahMeta(number: 4, nameAr: 'النساء', nameTransliteration: 'An-Nisa', ayahCount: 176, revelationPlace: 'medinan', revelationOrder: 92),
    SurahMeta(number: 5, nameAr: 'المائدة', nameTransliteration: 'Al-Maida', ayahCount: 120, revelationPlace: 'medinan', revelationOrder: 112),
    SurahMeta(number: 6, nameAr: 'الأنعام', nameTransliteration: 'Al-Anam', ayahCount: 165, revelationPlace: 'meccan', revelationOrder: 55),
    SurahMeta(number: 7, nameAr: 'الأعراف', nameTransliteration: 'Al-Araf', ayahCount: 206, revelationPlace: 'meccan', revelationOrder: 39),
    SurahMeta(number: 8, nameAr: 'الأنفال', nameTransliteration: 'Al-Anfal', ayahCount: 75, revelationPlace: 'medinan', revelationOrder: 88),
    SurahMeta(number: 9, nameAr: 'التوبة', nameTransliteration: 'At-Tawba', ayahCount: 129, revelationPlace: 'medinan', revelationOrder: 113),
    SurahMeta(number: 10, nameAr: 'يونس', nameTransliteration: 'Yunus', ayahCount: 109, revelationPlace: 'meccan', revelationOrder: 51),
    SurahMeta(number: 11, nameAr: 'هود', nameTransliteration: 'Hud', ayahCount: 123, revelationPlace: 'meccan', revelationOrder: 52),
    SurahMeta(number: 12, nameAr: 'يوسف', nameTransliteration: 'Yusuf', ayahCount: 111, revelationPlace: 'meccan', revelationOrder: 53),
    SurahMeta(number: 13, nameAr: 'الرعد', nameTransliteration: 'Ar-Rad', ayahCount: 43, revelationPlace: 'medinan', revelationOrder: 96),
    SurahMeta(number: 14, nameAr: 'إبراهيم', nameTransliteration: 'Ibrahim', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 72),
    SurahMeta(number: 15, nameAr: 'الحجر', nameTransliteration: 'Al-Hijr', ayahCount: 99, revelationPlace: 'meccan', revelationOrder: 54),
    SurahMeta(number: 16, nameAr: 'النحل', nameTransliteration: 'An-Nahl', ayahCount: 128, revelationPlace: 'meccan', revelationOrder: 70),
    SurahMeta(number: 17, nameAr: 'الإسراء', nameTransliteration: 'Al-Isra', ayahCount: 111, revelationPlace: 'meccan', revelationOrder: 50),
    SurahMeta(number: 18, nameAr: 'الكهف', nameTransliteration: 'Al-Kahf', ayahCount: 110, revelationPlace: 'meccan', revelationOrder: 69),
    SurahMeta(number: 19, nameAr: 'مريم', nameTransliteration: 'Maryam', ayahCount: 98, revelationPlace: 'meccan', revelationOrder: 44),
    SurahMeta(number: 20, nameAr: 'طه', nameTransliteration: 'Ta-Ha', ayahCount: 135, revelationPlace: 'meccan', revelationOrder: 45),
    SurahMeta(number: 21, nameAr: 'الأنبياء', nameTransliteration: 'Al-Anbiya', ayahCount: 112, revelationPlace: 'meccan', revelationOrder: 73),
    SurahMeta(number: 22, nameAr: 'الحج', nameTransliteration: 'Al-Hajj', ayahCount: 78, revelationPlace: 'medinan', revelationOrder: 103),
    SurahMeta(number: 23, nameAr: 'المؤمنون', nameTransliteration: 'Al-Muminun', ayahCount: 118, revelationPlace: 'meccan', revelationOrder: 74),
    SurahMeta(number: 24, nameAr: 'النور', nameTransliteration: 'An-Nur', ayahCount: 64, revelationPlace: 'medinan', revelationOrder: 102),
    SurahMeta(number: 25, nameAr: 'الفرقان', nameTransliteration: 'Al-Furqan', ayahCount: 77, revelationPlace: 'meccan', revelationOrder: 42),
    SurahMeta(number: 26, nameAr: 'الشعراء', nameTransliteration: 'Ash-Shuara', ayahCount: 227, revelationPlace: 'meccan', revelationOrder: 47),
    SurahMeta(number: 27, nameAr: 'النمل', nameTransliteration: 'An-Naml', ayahCount: 93, revelationPlace: 'meccan', revelationOrder: 48),
    SurahMeta(number: 28, nameAr: 'القصص', nameTransliteration: 'Al-Qasas', ayahCount: 88, revelationPlace: 'meccan', revelationOrder: 49),
    SurahMeta(number: 29, nameAr: 'العنكبوت', nameTransliteration: 'Al-Ankabut', ayahCount: 69, revelationPlace: 'meccan', revelationOrder: 85),
    SurahMeta(number: 30, nameAr: 'الروم', nameTransliteration: 'Ar-Rum', ayahCount: 60, revelationPlace: 'meccan', revelationOrder: 84),
    SurahMeta(number: 31, nameAr: 'لقمان', nameTransliteration: 'Luqman', ayahCount: 34, revelationPlace: 'meccan', revelationOrder: 57),
    SurahMeta(number: 32, nameAr: 'السجدة', nameTransliteration: 'As-Sajda', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 75),
    SurahMeta(number: 33, nameAr: 'الأحزاب', nameTransliteration: 'Al-Ahzab', ayahCount: 73, revelationPlace: 'medinan', revelationOrder: 90),
    SurahMeta(number: 34, nameAr: 'سبأ', nameTransliteration: 'Saba', ayahCount: 54, revelationPlace: 'meccan', revelationOrder: 58),
    SurahMeta(number: 35, nameAr: 'فاطر', nameTransliteration: 'Fatir', ayahCount: 45, revelationPlace: 'meccan', revelationOrder: 43),
    SurahMeta(number: 36, nameAr: 'يس', nameTransliteration: 'Ya-Sin', ayahCount: 83, revelationPlace: 'meccan', revelationOrder: 41),
    SurahMeta(number: 37, nameAr: 'الصافات', nameTransliteration: 'As-Saffat', ayahCount: 182, revelationPlace: 'meccan', revelationOrder: 56),
    SurahMeta(number: 38, nameAr: 'ص', nameTransliteration: 'Sad', ayahCount: 88, revelationPlace: 'meccan', revelationOrder: 38),
    SurahMeta(number: 39, nameAr: 'الزمر', nameTransliteration: 'Az-Zumar', ayahCount: 75, revelationPlace: 'meccan', revelationOrder: 59),
    SurahMeta(number: 40, nameAr: 'غافر', nameTransliteration: 'Ghafir', ayahCount: 85, revelationPlace: 'meccan', revelationOrder: 60),
    SurahMeta(number: 41, nameAr: 'فصلت', nameTransliteration: 'Fussilat', ayahCount: 54, revelationPlace: 'meccan', revelationOrder: 61),
    SurahMeta(number: 42, nameAr: 'الشورى', nameTransliteration: 'Ash-Shura', ayahCount: 53, revelationPlace: 'meccan', revelationOrder: 62),
    SurahMeta(number: 43, nameAr: 'الزخرف', nameTransliteration: 'Az-Zukhruf', ayahCount: 89, revelationPlace: 'meccan', revelationOrder: 63),
    SurahMeta(number: 44, nameAr: 'الدخان', nameTransliteration: 'Ad-Dukhan', ayahCount: 59, revelationPlace: 'meccan', revelationOrder: 64),
    SurahMeta(number: 45, nameAr: 'الجاثية', nameTransliteration: 'Al-Jathiya', ayahCount: 37, revelationPlace: 'meccan', revelationOrder: 65),
    SurahMeta(number: 46, nameAr: 'الأحقاف', nameTransliteration: 'Al-Ahqaf', ayahCount: 35, revelationPlace: 'meccan', revelationOrder: 66),
    SurahMeta(number: 47, nameAr: 'محمد', nameTransliteration: 'Muhammad', ayahCount: 38, revelationPlace: 'medinan', revelationOrder: 95),
    SurahMeta(number: 48, nameAr: 'الفتح', nameTransliteration: 'Al-Fath', ayahCount: 29, revelationPlace: 'medinan', revelationOrder: 111),
    SurahMeta(number: 49, nameAr: 'الحجرات', nameTransliteration: 'Al-Hujurat', ayahCount: 18, revelationPlace: 'medinan', revelationOrder: 106),
    SurahMeta(number: 50, nameAr: 'ق', nameTransliteration: 'Qaf', ayahCount: 45, revelationPlace: 'meccan', revelationOrder: 34),
    SurahMeta(number: 51, nameAr: 'الذاريات', nameTransliteration: 'Adh-Dhariyat', ayahCount: 60, revelationPlace: 'meccan', revelationOrder: 67),
    SurahMeta(number: 52, nameAr: 'الطور', nameTransliteration: 'At-Tur', ayahCount: 49, revelationPlace: 'meccan', revelationOrder: 76),
    SurahMeta(number: 53, nameAr: 'النجم', nameTransliteration: 'An-Najm', ayahCount: 62, revelationPlace: 'meccan', revelationOrder: 23),
    SurahMeta(number: 54, nameAr: 'القمر', nameTransliteration: 'Al-Qamar', ayahCount: 55, revelationPlace: 'meccan', revelationOrder: 37),
    SurahMeta(number: 55, nameAr: 'الرحمن', nameTransliteration: 'Ar-Rahman', ayahCount: 78, revelationPlace: 'medinan', revelationOrder: 97),
    SurahMeta(number: 56, nameAr: 'الواقعة', nameTransliteration: 'Al-Waqia', ayahCount: 96, revelationPlace: 'meccan', revelationOrder: 46),
    SurahMeta(number: 57, nameAr: 'الحديد', nameTransliteration: 'Al-Hadid', ayahCount: 29, revelationPlace: 'medinan', revelationOrder: 94),
    SurahMeta(number: 58, nameAr: 'المجادلة', nameTransliteration: 'Al-Mujadila', ayahCount: 22, revelationPlace: 'medinan', revelationOrder: 105),
    SurahMeta(number: 59, nameAr: 'الحشر', nameTransliteration: 'Al-Hashr', ayahCount: 24, revelationPlace: 'medinan', revelationOrder: 101),
    SurahMeta(number: 60, nameAr: 'الممتحنة', nameTransliteration: 'Al-Mumtahana', ayahCount: 13, revelationPlace: 'medinan', revelationOrder: 91),
    SurahMeta(number: 61, nameAr: 'الصف', nameTransliteration: 'As-Saff', ayahCount: 14, revelationPlace: 'medinan', revelationOrder: 109),
    SurahMeta(number: 62, nameAr: 'الجمعة', nameTransliteration: 'Al-Jumua', ayahCount: 11, revelationPlace: 'medinan', revelationOrder: 110),
    SurahMeta(number: 63, nameAr: 'المنافقون', nameTransliteration: 'Al-Munafiqun', ayahCount: 11, revelationPlace: 'medinan', revelationOrder: 104),
    SurahMeta(number: 64, nameAr: 'التغابن', nameTransliteration: 'At-Taghabun', ayahCount: 18, revelationPlace: 'medinan', revelationOrder: 108),
    SurahMeta(number: 65, nameAr: 'الطلاق', nameTransliteration: 'At-Talaq', ayahCount: 12, revelationPlace: 'medinan', revelationOrder: 99),
    SurahMeta(number: 66, nameAr: 'التحريم', nameTransliteration: 'At-Tahrim', ayahCount: 12, revelationPlace: 'medinan', revelationOrder: 107),
    SurahMeta(number: 67, nameAr: 'الملك', nameTransliteration: 'Al-Mulk', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 77),
    SurahMeta(number: 68, nameAr: 'القلم', nameTransliteration: 'Al-Qalam', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 2),
    SurahMeta(number: 69, nameAr: 'الحاقة', nameTransliteration: 'Al-Haqqa', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 78),
    SurahMeta(number: 70, nameAr: 'المعارج', nameTransliteration: 'Al-Maarij', ayahCount: 44, revelationPlace: 'meccan', revelationOrder: 79),
    SurahMeta(number: 71, nameAr: 'نوح', nameTransliteration: 'Nuh', ayahCount: 28, revelationPlace: 'meccan', revelationOrder: 71),
    SurahMeta(number: 72, nameAr: 'الجن', nameTransliteration: 'Al-Jinn', ayahCount: 28, revelationPlace: 'meccan', revelationOrder: 40),
    SurahMeta(number: 73, nameAr: 'المزمل', nameTransliteration: 'Al-Muzzammil', ayahCount: 20, revelationPlace: 'meccan', revelationOrder: 3),
    SurahMeta(number: 74, nameAr: 'المدثر', nameTransliteration: 'Al-Muddaththir', ayahCount: 56, revelationPlace: 'meccan', revelationOrder: 4),
    SurahMeta(number: 75, nameAr: 'القيامة', nameTransliteration: 'Al-Qiyama', ayahCount: 40, revelationPlace: 'meccan', revelationOrder: 31),
    SurahMeta(number: 76, nameAr: 'الإنسان', nameTransliteration: 'Al-Insan', ayahCount: 31, revelationPlace: 'medinan', revelationOrder: 98),
    SurahMeta(number: 77, nameAr: 'المرسلات', nameTransliteration: 'Al-Mursalat', ayahCount: 50, revelationPlace: 'meccan', revelationOrder: 33),
    SurahMeta(number: 78, nameAr: 'النبأ', nameTransliteration: 'An-Naba', ayahCount: 40, revelationPlace: 'meccan', revelationOrder: 80),
    SurahMeta(number: 79, nameAr: 'النازعات', nameTransliteration: 'An-Naziat', ayahCount: 46, revelationPlace: 'meccan', revelationOrder: 81),
    SurahMeta(number: 80, nameAr: 'عبس', nameTransliteration: 'Abasa', ayahCount: 42, revelationPlace: 'meccan', revelationOrder: 24),
    SurahMeta(number: 81, nameAr: 'التكوير', nameTransliteration: 'At-Takwir', ayahCount: 29, revelationPlace: 'meccan', revelationOrder: 7),
    SurahMeta(number: 82, nameAr: 'الانفطار', nameTransliteration: 'Al-Infitar', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 82),
    SurahMeta(number: 83, nameAr: 'المطففين', nameTransliteration: 'Al-Mutaffifin', ayahCount: 36, revelationPlace: 'meccan', revelationOrder: 86),
    SurahMeta(number: 84, nameAr: 'الانشقاق', nameTransliteration: 'Al-Inshiqaq', ayahCount: 25, revelationPlace: 'meccan', revelationOrder: 83),
    SurahMeta(number: 85, nameAr: 'البروج', nameTransliteration: 'Al-Buruj', ayahCount: 22, revelationPlace: 'meccan', revelationOrder: 27),
    SurahMeta(number: 86, nameAr: 'الطارق', nameTransliteration: 'At-Tariq', ayahCount: 17, revelationPlace: 'meccan', revelationOrder: 36),
    SurahMeta(number: 87, nameAr: 'الأعلى', nameTransliteration: 'Al-Ala', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 8),
    SurahMeta(number: 88, nameAr: 'الغاشية', nameTransliteration: 'Al-Ghashiya', ayahCount: 26, revelationPlace: 'meccan', revelationOrder: 68),
    SurahMeta(number: 89, nameAr: 'الفجر', nameTransliteration: 'Al-Fajr', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 10),
    SurahMeta(number: 90, nameAr: 'البلد', nameTransliteration: 'Al-Balad', ayahCount: 20, revelationPlace: 'meccan', revelationOrder: 35),
    SurahMeta(number: 91, nameAr: 'الشمس', nameTransliteration: 'Ash-Shams', ayahCount: 15, revelationPlace: 'meccan', revelationOrder: 26),
    SurahMeta(number: 92, nameAr: 'الليل', nameTransliteration: 'Al-Layl', ayahCount: 21, revelationPlace: 'meccan', revelationOrder: 9),
    SurahMeta(number: 93, nameAr: 'الضحى', nameTransliteration: 'Ad-Duha', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 11),
    SurahMeta(number: 94, nameAr: 'الشرح', nameTransliteration: 'Ash-Sharh', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 12),
    SurahMeta(number: 95, nameAr: 'التين', nameTransliteration: 'At-Tin', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 28),
    SurahMeta(number: 96, nameAr: 'العلق', nameTransliteration: 'Al-Alaq', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 1),
    SurahMeta(number: 97, nameAr: 'القدر', nameTransliteration: 'Al-Qadr', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 25),
    SurahMeta(number: 98, nameAr: 'البينة', nameTransliteration: 'Al-Bayyina', ayahCount: 8, revelationPlace: 'medinan', revelationOrder: 100),
    SurahMeta(number: 99, nameAr: 'الزلزلة', nameTransliteration: 'Az-Zalzala', ayahCount: 8, revelationPlace: 'medinan', revelationOrder: 93),
    SurahMeta(number: 100, nameAr: 'العاديات', nameTransliteration: 'Al-Adiyat', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 14),
    SurahMeta(number: 101, nameAr: 'القارعة', nameTransliteration: 'Al-Qaria', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 30),
    SurahMeta(number: 102, nameAr: 'التكاثر', nameTransliteration: 'At-Takathur', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 16),
    SurahMeta(number: 103, nameAr: 'العصر', nameTransliteration: 'Al-Asr', ayahCount: 3, revelationPlace: 'meccan', revelationOrder: 13),
    SurahMeta(number: 104, nameAr: 'الهمزة', nameTransliteration: 'Al-Humaza', ayahCount: 9, revelationPlace: 'meccan', revelationOrder: 32),
    SurahMeta(number: 105, nameAr: 'الفيل', nameTransliteration: 'Al-Fil', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 19),
    SurahMeta(number: 106, nameAr: 'قريش', nameTransliteration: 'Quraysh', ayahCount: 4, revelationPlace: 'meccan', revelationOrder: 29),
    SurahMeta(number: 107, nameAr: 'الماعون', nameTransliteration: 'Al-Maun', ayahCount: 7, revelationPlace: 'meccan', revelationOrder: 17),
    SurahMeta(number: 108, nameAr: 'الكوثر', nameTransliteration: 'Al-Kawthar', ayahCount: 3, revelationPlace: 'meccan', revelationOrder: 15),
    SurahMeta(number: 109, nameAr: 'الكافرون', nameTransliteration: 'Al-Kafirun', ayahCount: 6, revelationPlace: 'meccan', revelationOrder: 18),
    SurahMeta(number: 110, nameAr: 'النصر', nameTransliteration: 'An-Nasr', ayahCount: 3, revelationPlace: 'medinan', revelationOrder: 114),
    SurahMeta(number: 111, nameAr: 'المسد', nameTransliteration: 'Al-Masad', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 6),
    SurahMeta(number: 112, nameAr: 'الإخلاص', nameTransliteration: 'Al-Ikhlas', ayahCount: 4, revelationPlace: 'meccan', revelationOrder: 22),
    SurahMeta(number: 113, nameAr: 'الفلق', nameTransliteration: 'Al-Falaq', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 20),
    SurahMeta(number: 114, nameAr: 'الناس', nameTransliteration: 'An-Nas', ayahCount: 6, revelationPlace: 'meccan', revelationOrder: 21),
  ];

  /// Look up a SurahMeta by number (1..114).
  static SurahMeta? byNumber(int number) {
    if (number < 1 || number > 114) return null;
    return surahs[number - 1];
  }

  /// Search by number, Arabic name, or English transcription.
  /// NEVER searches meanings (there are none stored).
  static List<SurahMeta> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;

    // Try number first
    final n = int.tryParse(q);
    if (n != null && n >= 1 && n <= 114) {
      return [surahs[n - 1]];
    }

    return surahs.where((s) {
      return s.nameAr.contains(q) ||
          s.nameTransliteration.toLowerCase().contains(q);
    }).toList();
  }
}
