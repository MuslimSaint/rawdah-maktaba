import 'models.dart';

/// Hardcoded skeleton of all 114 Surahs.
/// Like the 6 branches, this is architectural — never changes.
/// Only the PDF URLs and audio come from catalog.
class QuranSkeleton {
  static const List<SurahMeta> surahs = [
    SurahMeta(number: 1, nameAr: 'الفاتحة', nameTransliteration: 'Al-Fatiha', meaningEn: 'The Opening', ayahCount: 7, revelationPlace: 'meccan', revelationOrder: 5),
    SurahMeta(number: 2, nameAr: 'البقرة', nameTransliteration: 'Al-Baqara', meaningEn: 'The Cow', ayahCount: 286, revelationPlace: 'medinan', revelationOrder: 87),
    SurahMeta(number: 3, nameAr: 'آل عمران', nameTransliteration: 'Aal Imran', meaningEn: 'The Family of Imran', ayahCount: 200, revelationPlace: 'medinan', revelationOrder: 89),
    SurahMeta(number: 4, nameAr: 'النساء', nameTransliteration: 'An-Nisa', meaningEn: 'The Women', ayahCount: 176, revelationPlace: 'medinan', revelationOrder: 92),
    SurahMeta(number: 5, nameAr: 'المائدة', nameTransliteration: 'Al-Maida', meaningEn: 'The Table Spread', ayahCount: 120, revelationPlace: 'medinan', revelationOrder: 112),
    SurahMeta(number: 6, nameAr: 'الأنعام', nameTransliteration: 'Al-Anam', meaningEn: 'The Cattle', ayahCount: 165, revelationPlace: 'meccan', revelationOrder: 55),
    SurahMeta(number: 7, nameAr: 'الأعراف', nameTransliteration: 'Al-Araf', meaningEn: 'The Heights', ayahCount: 206, revelationPlace: 'meccan', revelationOrder: 39),
    SurahMeta(number: 8, nameAr: 'الأنفال', nameTransliteration: 'Al-Anfal', meaningEn: 'The Spoils of War', ayahCount: 75, revelationPlace: 'medinan', revelationOrder: 88),
    SurahMeta(number: 9, nameAr: 'التوبة', nameTransliteration: 'At-Tawba', meaningEn: 'The Repentance', ayahCount: 129, revelationPlace: 'medinan', revelationOrder: 113),
    SurahMeta(number: 10, nameAr: 'يونس', nameTransliteration: 'Yunus', meaningEn: 'Jonah', ayahCount: 109, revelationPlace: 'meccan', revelationOrder: 51),
    SurahMeta(number: 11, nameAr: 'هود', nameTransliteration: 'Hud', meaningEn: 'Hud', ayahCount: 123, revelationPlace: 'meccan', revelationOrder: 52),
    SurahMeta(number: 12, nameAr: 'يوسف', nameTransliteration: 'Yusuf', meaningEn: 'Joseph', ayahCount: 111, revelationPlace: 'meccan', revelationOrder: 53),
    SurahMeta(number: 13, nameAr: 'الرعد', nameTransliteration: 'Ar-Rad', meaningEn: 'The Thunder', ayahCount: 43, revelationPlace: 'medinan', revelationOrder: 96),
    SurahMeta(number: 14, nameAr: 'إبراهيم', nameTransliteration: 'Ibrahim', meaningEn: 'Abraham', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 72),
    SurahMeta(number: 15, nameAr: 'الحجر', nameTransliteration: 'Al-Hijr', meaningEn: 'The Rocky Tract', ayahCount: 99, revelationPlace: 'meccan', revelationOrder: 54),
    SurahMeta(number: 16, nameAr: 'النحل', nameTransliteration: 'An-Nahl', meaningEn: 'The Bee', ayahCount: 128, revelationPlace: 'meccan', revelationOrder: 70),
    SurahMeta(number: 17, nameAr: 'الإسراء', nameTransliteration: 'Al-Isra', meaningEn: 'The Night Journey', ayahCount: 111, revelationPlace: 'meccan', revelationOrder: 50),
    SurahMeta(number: 18, nameAr: 'الكهف', nameTransliteration: 'Al-Kahf', meaningEn: 'The Cave', ayahCount: 110, revelationPlace: 'meccan', revelationOrder: 69),
    SurahMeta(number: 19, nameAr: 'مريم', nameTransliteration: 'Maryam', meaningEn: 'Mary', ayahCount: 98, revelationPlace: 'meccan', revelationOrder: 44),
    SurahMeta(number: 20, nameAr: 'طه', nameTransliteration: 'Ta-Ha', meaningEn: 'Ta-Ha', ayahCount: 135, revelationPlace: 'meccan', revelationOrder: 45),
    SurahMeta(number: 21, nameAr: 'الأنبياء', nameTransliteration: 'Al-Anbiya', meaningEn: 'The Prophets', ayahCount: 112, revelationPlace: 'meccan', revelationOrder: 73),
    SurahMeta(number: 22, nameAr: 'الحج', nameTransliteration: 'Al-Hajj', meaningEn: 'The Pilgrimage', ayahCount: 78, revelationPlace: 'medinan', revelationOrder: 103),
    SurahMeta(number: 23, nameAr: 'المؤمنون', nameTransliteration: 'Al-Muminun', meaningEn: 'The Believers', ayahCount: 118, revelationPlace: 'meccan', revelationOrder: 74),
    SurahMeta(number: 24, nameAr: 'النور', nameTransliteration: 'An-Nur', meaningEn: 'The Light', ayahCount: 64, revelationPlace: 'medinan', revelationOrder: 102),
    SurahMeta(number: 25, nameAr: 'الفرقان', nameTransliteration: 'Al-Furqan', meaningEn: 'The Criterion', ayahCount: 77, revelationPlace: 'meccan', revelationOrder: 42),
    SurahMeta(number: 26, nameAr: 'الشعراء', nameTransliteration: 'Ash-Shuara', meaningEn: 'The Poets', ayahCount: 227, revelationPlace: 'meccan', revelationOrder: 47),
    SurahMeta(number: 27, nameAr: 'النمل', nameTransliteration: 'An-Naml', meaningEn: 'The Ant', ayahCount: 93, revelationPlace: 'meccan', revelationOrder: 48),
    SurahMeta(number: 28, nameAr: 'القصص', nameTransliteration: 'Al-Qasas', meaningEn: 'The Stories', ayahCount: 88, revelationPlace: 'meccan', revelationOrder: 49),
    SurahMeta(number: 29, nameAr: 'العنكبوت', nameTransliteration: 'Al-Ankabut', meaningEn: 'The Spider', ayahCount: 69, revelationPlace: 'meccan', revelationOrder: 85),
    SurahMeta(number: 30, nameAr: 'الروم', nameTransliteration: 'Ar-Rum', meaningEn: 'The Romans', ayahCount: 60, revelationPlace: 'meccan', revelationOrder: 84),
    SurahMeta(number: 31, nameAr: 'لقمان', nameTransliteration: 'Luqman', meaningEn: 'Luqman', ayahCount: 34, revelationPlace: 'meccan', revelationOrder: 57),
    SurahMeta(number: 32, nameAr: 'السجدة', nameTransliteration: 'As-Sajda', meaningEn: 'The Prostration', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 75),
    SurahMeta(number: 33, nameAr: 'الأحزاب', nameTransliteration: 'Al-Ahzab', meaningEn: 'The Confederates', ayahCount: 73, revelationPlace: 'medinan', revelationOrder: 90),
    SurahMeta(number: 34, nameAr: 'سبأ', nameTransliteration: 'Saba', meaningEn: 'Sheba', ayahCount: 54, revelationPlace: 'meccan', revelationOrder: 58),
    SurahMeta(number: 35, nameAr: 'فاطر', nameTransliteration: 'Fatir', meaningEn: 'The Originator', ayahCount: 45, revelationPlace: 'meccan', revelationOrder: 43),
    SurahMeta(number: 36, nameAr: 'يس', nameTransliteration: 'Ya-Sin', meaningEn: 'Ya-Sin', ayahCount: 83, revelationPlace: 'meccan', revelationOrder: 41),
    SurahMeta(number: 37, nameAr: 'الصافات', nameTransliteration: 'As-Saffat', meaningEn: 'Those Ranged in Ranks', ayahCount: 182, revelationPlace: 'meccan', revelationOrder: 56),
    SurahMeta(number: 38, nameAr: 'ص', nameTransliteration: 'Sad', meaningEn: 'The Letter Sad', ayahCount: 88, revelationPlace: 'meccan', revelationOrder: 38),
    SurahMeta(number: 39, nameAr: 'الزمر', nameTransliteration: 'Az-Zumar', meaningEn: 'The Groups', ayahCount: 75, revelationPlace: 'meccan', revelationOrder: 59),
    SurahMeta(number: 40, nameAr: 'غافر', nameTransliteration: 'Ghafir', meaningEn: 'The Forgiver', ayahCount: 85, revelationPlace: 'meccan', revelationOrder: 60),
    SurahMeta(number: 41, nameAr: 'فصلت', nameTransliteration: 'Fussilat', meaningEn: 'Explained in Detail', ayahCount: 54, revelationPlace: 'meccan', revelationOrder: 61),
    SurahMeta(number: 42, nameAr: 'الشورى', nameTransliteration: 'Ash-Shura', meaningEn: 'The Consultation', ayahCount: 53, revelationPlace: 'meccan', revelationOrder: 62),
    SurahMeta(number: 43, nameAr: 'الزخرف', nameTransliteration: 'Az-Zukhruf', meaningEn: 'The Gold Adornments', ayahCount: 89, revelationPlace: 'meccan', revelationOrder: 63),
    SurahMeta(number: 44, nameAr: 'الدخان', nameTransliteration: 'Ad-Dukhan', meaningEn: 'The Smoke', ayahCount: 59, revelationPlace: 'meccan', revelationOrder: 64),
    SurahMeta(number: 45, nameAr: 'الجاثية', nameTransliteration: 'Al-Jathiya', meaningEn: 'The Kneeling', ayahCount: 37, revelationPlace: 'meccan', revelationOrder: 65),
    SurahMeta(number: 46, nameAr: 'الأحقاف', nameTransliteration: 'Al-Ahqaf', meaningEn: 'The Curved Sand Tracts', ayahCount: 35, revelationPlace: 'meccan', revelationOrder: 66),
    SurahMeta(number: 47, nameAr: 'محمد', nameTransliteration: 'Muhammad', meaningEn: 'Muhammad', ayahCount: 38, revelationPlace: 'medinan', revelationOrder: 95),
    SurahMeta(number: 48, nameAr: 'الفتح', nameTransliteration: 'Al-Fath', meaningEn: 'The Victory', ayahCount: 29, revelationPlace: 'medinan', revelationOrder: 111),
    SurahMeta(number: 49, nameAr: 'الحجرات', nameTransliteration: 'Al-Hujurat', meaningEn: 'The Dwellings', ayahCount: 18, revelationPlace: 'medinan', revelationOrder: 106),
    SurahMeta(number: 50, nameAr: 'ق', nameTransliteration: 'Qaf', meaningEn: 'The Letter Qaf', ayahCount: 45, revelationPlace: 'meccan', revelationOrder: 34),
    SurahMeta(number: 51, nameAr: 'الذاريات', nameTransliteration: 'Adh-Dhariyat', meaningEn: 'The Winnowing Winds', ayahCount: 60, revelationPlace: 'meccan', revelationOrder: 67),
    SurahMeta(number: 52, nameAr: 'الطور', nameTransliteration: 'At-Tur', meaningEn: 'The Mount', ayahCount: 49, revelationPlace: 'meccan', revelationOrder: 76),
    SurahMeta(number: 53, nameAr: 'النجم', nameTransliteration: 'An-Najm', meaningEn: 'The Star', ayahCount: 62, revelationPlace: 'meccan', revelationOrder: 23),
    SurahMeta(number: 54, nameAr: 'القمر', nameTransliteration: 'Al-Qamar', meaningEn: 'The Moon', ayahCount: 55, revelationPlace: 'meccan', revelationOrder: 37),
    SurahMeta(number: 55, nameAr: 'الرحمن', nameTransliteration: 'Ar-Rahman', meaningEn: 'The Most Merciful', ayahCount: 78, revelationPlace: 'medinan', revelationOrder: 97),
    SurahMeta(number: 56, nameAr: 'الواقعة', nameTransliteration: 'Al-Waqia', meaningEn: 'The Event', ayahCount: 96, revelationPlace: 'meccan', revelationOrder: 46),
    SurahMeta(number: 57, nameAr: 'الحديد', nameTransliteration: 'Al-Hadid', meaningEn: 'The Iron', ayahCount: 29, revelationPlace: 'medinan', revelationOrder: 94),
    SurahMeta(number: 58, nameAr: 'المجادلة', nameTransliteration: 'Al-Mujadila', meaningEn: 'The Pleading Woman', ayahCount: 22, revelationPlace: 'medinan', revelationOrder: 105),
    SurahMeta(number: 59, nameAr: 'الحشر', nameTransliteration: 'Al-Hashr', meaningEn: 'The Gathering', ayahCount: 24, revelationPlace: 'medinan', revelationOrder: 101),
    SurahMeta(number: 60, nameAr: 'الممتحنة', nameTransliteration: 'Al-Mumtahana', meaningEn: 'The Woman to be Examined', ayahCount: 13, revelationPlace: 'medinan', revelationOrder: 91),
    SurahMeta(number: 61, nameAr: 'الصف', nameTransliteration: 'As-Saff', meaningEn: 'The Ranks', ayahCount: 14, revelationPlace: 'medinan', revelationOrder: 109),
    SurahMeta(number: 62, nameAr: 'الجمعة', nameTransliteration: 'Al-Jumua', meaningEn: 'Friday', ayahCount: 11, revelationPlace: 'medinan', revelationOrder: 110),
    SurahMeta(number: 63, nameAr: 'المنافقون', nameTransliteration: 'Al-Munafiqun', meaningEn: 'The Hypocrites', ayahCount: 11, revelationPlace: 'medinan', revelationOrder: 104),
    SurahMeta(number: 64, nameAr: 'التغابن', nameTransliteration: 'At-Taghabun', meaningEn: 'Mutual Disillusion', ayahCount: 18, revelationPlace: 'medinan', revelationOrder: 108),
    SurahMeta(number: 65, nameAr: 'الطلاق', nameTransliteration: 'At-Talaq', meaningEn: 'The Divorce', ayahCount: 12, revelationPlace: 'medinan', revelationOrder: 99),
    SurahMeta(number: 66, nameAr: 'التحريم', nameTransliteration: 'At-Tahrim', meaningEn: 'The Prohibition', ayahCount: 12, revelationPlace: 'medinan', revelationOrder: 107),
    SurahMeta(number: 67, nameAr: 'الملك', nameTransliteration: 'Al-Mulk', meaningEn: 'The Sovereignty', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 77),
    SurahMeta(number: 68, nameAr: 'القلم', nameTransliteration: 'Al-Qalam', meaningEn: 'The Pen', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 2),
    SurahMeta(number: 69, nameAr: 'الحاقة', nameTransliteration: 'Al-Haqqa', meaningEn: 'The Reality', ayahCount: 52, revelationPlace: 'meccan', revelationOrder: 78),
    SurahMeta(number: 70, nameAr: 'المعارج', nameTransliteration: 'Al-Maarij', meaningEn: 'The Ascending Stairways', ayahCount: 44, revelationPlace: 'meccan', revelationOrder: 79),
    SurahMeta(number: 71, nameAr: 'نوح', nameTransliteration: 'Nuh', meaningEn: 'Noah', ayahCount: 28, revelationPlace: 'meccan', revelationOrder: 71),
    SurahMeta(number: 72, nameAr: 'الجن', nameTransliteration: 'Al-Jinn', meaningEn: 'The Jinn', ayahCount: 28, revelationPlace: 'meccan', revelationOrder: 40),
    SurahMeta(number: 73, nameAr: 'المزمل', nameTransliteration: 'Al-Muzzammil', meaningEn: 'The Enshrouded One', ayahCount: 20, revelationPlace: 'meccan', revelationOrder: 3),
    SurahMeta(number: 74, nameAr: 'المدثر', nameTransliteration: 'Al-Muddaththir', meaningEn: 'The Cloaked One', ayahCount: 56, revelationPlace: 'meccan', revelationOrder: 4),
    SurahMeta(number: 75, nameAr: 'القيامة', nameTransliteration: 'Al-Qiyama', meaningEn: 'The Resurrection', ayahCount: 40, revelationPlace: 'meccan', revelationOrder: 31),
    SurahMeta(number: 76, nameAr: 'الإنسان', nameTransliteration: 'Al-Insan', meaningEn: 'Man', ayahCount: 31, revelationPlace: 'medinan', revelationOrder: 98),
    SurahMeta(number: 77, nameAr: 'المرسلات', nameTransliteration: 'Al-Mursalat', meaningEn: 'The Emissaries', ayahCount: 50, revelationPlace: 'meccan', revelationOrder: 33),
    SurahMeta(number: 78, nameAr: 'النبأ', nameTransliteration: 'An-Naba', meaningEn: 'The Announcement', ayahCount: 40, revelationPlace: 'meccan', revelationOrder: 80),
    SurahMeta(number: 79, nameAr: 'النازعات', nameTransliteration: 'An-Naziat', meaningEn: 'Those Who Pull Out', ayahCount: 46, revelationPlace: 'meccan', revelationOrder: 81),
    SurahMeta(number: 80, nameAr: 'عبس', nameTransliteration: 'Abasa', meaningEn: 'He Frowned', ayahCount: 42, revelationPlace: 'meccan', revelationOrder: 24),
    SurahMeta(number: 81, nameAr: 'التكوير', nameTransliteration: 'At-Takwir', meaningEn: 'The Overthrowing', ayahCount: 29, revelationPlace: 'meccan', revelationOrder: 7),
    SurahMeta(number: 82, nameAr: 'الانفطار', nameTransliteration: 'Al-Infitar', meaningEn: 'The Cleaving', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 82),
    SurahMeta(number: 83, nameAr: 'المطففين', nameTransliteration: 'Al-Mutaffifin', meaningEn: 'Those Who Deal in Fraud', ayahCount: 36, revelationPlace: 'meccan', revelationOrder: 86),
    SurahMeta(number: 84, nameAr: 'الانشقاق', nameTransliteration: 'Al-Inshiqaq', meaningEn: 'The Splitting Asunder', ayahCount: 25, revelationPlace: 'meccan', revelationOrder: 83),
    SurahMeta(number: 85, nameAr: 'البروج', nameTransliteration: 'Al-Buruj', meaningEn: 'The Mansions of the Stars', ayahCount: 22, revelationPlace: 'meccan', revelationOrder: 27),
    SurahMeta(number: 86, nameAr: 'الطارق', nameTransliteration: 'At-Tariq', meaningEn: 'The Night Comer', ayahCount: 17, revelationPlace: 'meccan', revelationOrder: 36),
    SurahMeta(number: 87, nameAr: 'الأعلى', nameTransliteration: 'Al-Ala', meaningEn: 'The Most High', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 8),
    SurahMeta(number: 88, nameAr: 'الغاشية', nameTransliteration: 'Al-Ghashiya', meaningEn: 'The Overwhelming', ayahCount: 26, revelationPlace: 'meccan', revelationOrder: 68),
    SurahMeta(number: 89, nameAr: 'الفجر', nameTransliteration: 'Al-Fajr', meaningEn: 'The Dawn', ayahCount: 30, revelationPlace: 'meccan', revelationOrder: 10),
    SurahMeta(number: 90, nameAr: 'البلد', nameTransliteration: 'Al-Balad', meaningEn: 'The City', ayahCount: 20, revelationPlace: 'meccan', revelationOrder: 35),
    SurahMeta(number: 91, nameAr: 'الشمس', nameTransliteration: 'Ash-Shams', meaningEn: 'The Sun', ayahCount: 15, revelationPlace: 'meccan', revelationOrder: 26),
    SurahMeta(number: 92, nameAr: 'الليل', nameTransliteration: 'Al-Layl', meaningEn: 'The Night', ayahCount: 21, revelationPlace: 'meccan', revelationOrder: 9),
    SurahMeta(number: 93, nameAr: 'الضحى', nameTransliteration: 'Ad-Duha', meaningEn: 'The Morning Hours', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 11),
    SurahMeta(number: 94, nameAr: 'الشرح', nameTransliteration: 'Ash-Sharh', meaningEn: 'The Relief', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 12),
    SurahMeta(number: 95, nameAr: 'التين', nameTransliteration: 'At-Tin', meaningEn: 'The Fig', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 28),
    SurahMeta(number: 96, nameAr: 'العلق', nameTransliteration: 'Al-Alaq', meaningEn: 'The Clot', ayahCount: 19, revelationPlace: 'meccan', revelationOrder: 1),
    SurahMeta(number: 97, nameAr: 'القدر', nameTransliteration: 'Al-Qadr', meaningEn: 'The Night of Decree', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 25),
    SurahMeta(number: 98, nameAr: 'البينة', nameTransliteration: 'Al-Bayyina', meaningEn: 'The Clear Evidence', ayahCount: 8, revelationPlace: 'medinan', revelationOrder: 100),
    SurahMeta(number: 99, nameAr: 'الزلزلة', nameTransliteration: 'Az-Zalzala', meaningEn: 'The Earthquake', ayahCount: 8, revelationPlace: 'medinan', revelationOrder: 93),
    SurahMeta(number: 100, nameAr: 'العاديات', nameTransliteration: 'Al-Adiyat', meaningEn: 'The Chargers', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 14),
    SurahMeta(number: 101, nameAr: 'القارعة', nameTransliteration: 'Al-Qaria', meaningEn: 'The Striking Hour', ayahCount: 11, revelationPlace: 'meccan', revelationOrder: 30),
    SurahMeta(number: 102, nameAr: 'التكاثر', nameTransliteration: 'At-Takathur', meaningEn: 'The Piling Up', ayahCount: 8, revelationPlace: 'meccan', revelationOrder: 16),
    SurahMeta(number: 103, nameAr: 'العصر', nameTransliteration: 'Al-Asr', meaningEn: 'The Time', ayahCount: 3, revelationPlace: 'meccan', revelationOrder: 13),
    SurahMeta(number: 104, nameAr: 'الهمزة', nameTransliteration: 'Al-Humaza', meaningEn: 'The Slanderer', ayahCount: 9, revelationPlace: 'meccan', revelationOrder: 32),
    SurahMeta(number: 105, nameAr: 'الفيل', nameTransliteration: 'Al-Fil', meaningEn: 'The Elephant', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 19),
    SurahMeta(number: 106, nameAr: 'قريش', nameTransliteration: 'Quraysh', meaningEn: 'Quraysh', ayahCount: 4, revelationPlace: 'meccan', revelationOrder: 29),
    SurahMeta(number: 107, nameAr: 'الماعون', nameTransliteration: 'Al-Maun', meaningEn: 'Small Kindnesses', ayahCount: 7, revelationPlace: 'meccan', revelationOrder: 17),
    SurahMeta(number: 108, nameAr: 'الكوثر', nameTransliteration: 'Al-Kawthar', meaningEn: 'The Abundance', ayahCount: 3, revelationPlace: 'meccan', revelationOrder: 15),
    SurahMeta(number: 109, nameAr: 'الكافرون', nameTransliteration: 'Al-Kafirun', meaningEn: 'The Disbelievers', ayahCount: 6, revelationPlace: 'meccan', revelationOrder: 18),
    SurahMeta(number: 110, nameAr: 'النصر', nameTransliteration: 'An-Nasr', meaningEn: 'The Divine Support', ayahCount: 3, revelationPlace: 'medinan', revelationOrder: 114),
    SurahMeta(number: 111, nameAr: 'المسد', nameTransliteration: 'Al-Masad', meaningEn: 'The Palm Fiber', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 6),
    SurahMeta(number: 112, nameAr: 'الإخلاص', nameTransliteration: 'Al-Ikhlas', meaningEn: 'The Sincerity', ayahCount: 4, revelationPlace: 'meccan', revelationOrder: 22),
    SurahMeta(number: 113, nameAr: 'الفلق', nameTransliteration: 'Al-Falaq', meaningEn: 'The Daybreak', ayahCount: 5, revelationPlace: 'meccan', revelationOrder: 20),
    SurahMeta(number: 114, nameAr: 'الناس', nameTransliteration: 'An-Nas', meaningEn: 'Mankind', ayahCount: 6, revelationPlace: 'meccan', revelationOrder: 21),
  ];

  /// Look up a SurahMeta by number (1..114).
  static SurahMeta? byNumber(int number) {
    if (number < 1 || number > 114) return null;
    return surahs[number - 1];
  }

  /// Case-insensitive search by number, Arabic name, or transliteration.
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
          s.nameTransliteration.toLowerCase().contains(q) ||
          s.meaningEn.toLowerCase().contains(q);
    }).toList();
  }
}
