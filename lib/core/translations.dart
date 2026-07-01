/// Translation system for Maktabatu Rawda.
/// Supports Arabic (ar), English (en), and Amharic (am).
///
/// Rule: The app name مكتبة الروضة is NEVER translated.
/// It always appears in Arabic regardless of language setting.

class Tr {
  final String ar;
  final String en;
  final String am;

  const Tr({required this.ar, required this.en, required this.am});

  /// Returns the string for the given language code.
  /// Falls back to English if the language is not found.
  String get(String lang) {
    switch (lang) {
      case 'ar':
        return ar;
      case 'am':
        return am;
      case 'en':
      default:
        return en;
    }
  }
}

/// A special translation type for text that never translates
/// (like the app name, Bismillah, hadith text).
class Fixed {
  final String value;
  const Fixed(this.value);
  String get(String lang) => value;
}

/// All app translations.
/// Access via T.appName.get(lang), T.home.get(lang), etc.
class T {
  // ─── App Identity (never translated) ─────────────────
  static const appName = Fixed('مكتبة الروضة');
  static const bismillah = Fixed('بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ');

  // ─── Welcome / Splash ────────────────────────────────
  static const welcomeSubtitle = Tr(
    ar: 'مكتبتك الإسلامية الكاملة',
    en: 'Your complete Islamic library',
    am: 'ሙሉ የእስልምና ቤተ መጻሕፍትዎ',
  );

  static const feature1Title = Tr(
    ar: 'كتب معتمدة',
    en: 'Verified Books',
    am: 'የተረጋገጡ መጻሕፍት',
  );
  static const feature1Sub = Tr(
    ar: 'نصوص أصلية بصيغة PDF',
    en: 'Original certified PDF texts',
    am: 'የተረጋገጡ PDF ጽሑፎች',
  );

  static const feature2Title = Tr(
    ar: 'شروح العلماء',
    en: 'Scholar Explanations',
    am: 'የምሁራን ማብራሪያ',
  );
  static const feature2Sub = Tr(
    ar: 'تعلم مع شيوخ متخصصين',
    en: 'Learn with specialized scholars',
    am: 'ከልዩ ምሁራን ጋር ይማሩ',
  );

  static const feature3Title = Tr(
    ar: 'بدون إنترنت',
    en: 'Works Offline',
    am: 'ያለ ኢንተርኔት',
  );
  static const feature3Sub = Tr(
    ar: 'يعمل بدون شبكة بعد التحميل',
    en: 'No internet needed after download',
    am: 'ከወረደ በኋላ ኢንተርኔት አያስፈልግም',
  );

  static const beginJourney = Tr(
    ar: 'ابدأ رحلتك',
    en: 'Begin Your Journey',
    am: 'ጉዞዎን ይጀምሩ',
  );

  static const rawdahProject = Fixed('RAWDAH PROJECT');

  // ─── Auth ────────────────────────────────────────────
  static const signIn = Tr(ar: 'تسجيل الدخول', en: 'Sign In', am: 'ግባ');
  static const signUp = Tr(ar: 'إنشاء حساب', en: 'Create Account', am: 'መለያ ፍጠር');
  static const continueWithGoogle = Tr(
    ar: 'المتابعة بحساب Google',
    en: 'Continue with Google',
    am: 'በ Google ይቀጥሉ',
  );
  static const orUseEmail = Tr(
    ar: 'أو استخدم البريد الإلكتروني',
    en: 'or use email',
    am: 'ወይም ኢሜይል ይጠቀሙ',
  );
  static const fullName = Tr(ar: 'الاسم الكامل', en: 'Full Name', am: 'ሙሉ ስም');
  static const email = Tr(ar: 'البريد الإلكتروني', en: 'Email', am: 'ኢሜይል');
  static const password = Tr(ar: 'كلمة المرور', en: 'Password', am: 'የይለፍ ቃል');
  static const dontHaveAccount = Tr(
    ar: 'ليس لديك حساب؟',
    en: "Don't have an account?",
    am: 'መለያ የለዎትም?',
  );
  static const alreadyHaveAccount = Tr(
    ar: 'لديك حساب؟',
    en: 'Already have an account?',
    am: 'መለያ አለዎት?',
  );

  // ─── Bottom Navigation ───────────────────────────────
  static const home = Tr(ar: 'الرئيسية', en: 'Home', am: 'መነሻ');
  static const library = Tr(ar: 'المكتبة', en: 'Library', am: 'ቤተ መጻሕፍት');
  static const downloads = Tr(ar: 'التحميلات', en: 'Downloads', am: 'ውርዶች');
  static const settings = Tr(ar: 'الإعدادات', en: 'Settings', am: 'ቅንብሮች');

  // ─── Home Screen ─────────────────────────────────────
  static const continueReading = Tr(
    ar: 'تابع القراءة',
    en: 'Continue Reading',
    am: 'ማንበብ ቀጥሉ',
  );
  static const branches = Tr(
    ar: 'فروع العلم',
    en: 'Branches of Knowledge',
    am: 'የዕውቀት ዘርፎች',
  );
  static const books = Tr(ar: 'كتب', en: 'books', am: 'መጻሕፍት');
  static const completed = Tr(ar: 'مكتملة', en: 'Completed', am: 'ተጠናቅቋል');

  // ─── Branches ────────────────────────────────────────
  static const hadith = Tr(ar: 'حديث', en: 'Hadith', am: 'ሐዲስ');
  static const aqeedah = Tr(ar: 'عقيدة', en: 'Aqeedah', am: 'አቂዳ');
  static const fiqh = Tr(ar: 'فقه', en: 'Fiqh', am: 'ፊቅህ');
  static const seerah = Tr(ar: 'سيرة', en: 'Seerah', am: 'ሲራ');
  static const tafseer = Tr(ar: 'تفسير', en: 'Tafseer', am: 'ተፍሲር');
  static const arabicLang = Tr(
    ar: 'اللغة العربية',
    en: 'Arabic Language',
    am: 'አረብኛ ቋንቋ',
  );

  static const comingSoon = Tr(ar: 'قريباً', en: 'Coming Soon', am: 'በቅርቡ');
  static const noBooksYet = Tr(
    ar: 'لا توجد كتب في هذا القسم حالياً. نعمل على إضافتها.',
    en: 'No books available in this branch yet. We are working on adding them.',
    am: 'በዚህ ዘርፍ ምንም መጻሕፍት የሉም። እየሠራንበት ነው።',
  );

  // ─── Book Detail ─────────────────────────────────────
  static const bookDetails = Tr(
    ar: 'تفاصيل الكتاب',
    en: 'Book Details',
    am: 'የመጽሐፍ ዝርዝር',
  );
  static const author = Tr(ar: 'المؤلف', en: 'AUTHOR', am: 'ደራሲ');
  static const writtenBy = Tr(ar: 'تأليف', en: 'Written by', am: 'የተጻፈው በ');
  static const taughtBy = Tr(ar: 'شرح', en: 'Taught by', am: 'የሚያስተምሩት');
  static const teachingScholars = Tr(
    ar: 'الشيوخ المعلمون',
    en: 'Teaching Scholars',
    am: 'አስተማሪ ምሁራን',
  );
  static const scholarsExplain = Tr(
    ar: 'هؤلاء الشيوخ يقدمون شروحاً صوتية لهذا الكتاب.',
    en: 'These scholars provide audio explanations for this book.',
    am: 'እነዚህ ምሁራን የድምጽ ማብራሪያ ይሰጣሉ።',
  );

  static const downloadPdf = Tr(
    ar: 'تحميل الكتاب',
    en: 'Download PDF',
    am: 'PDF አውርድ',
  );
  static const downloading = Tr(
    ar: 'جاري التحميل',
    en: 'Downloading',
    am: 'በማውረድ ላይ',
  );
  static const openBook = Tr(
    ar: 'فتح الكتاب',
    en: 'Open Book',
    am: 'መጽሐፍ ክፈት',
  );
  static const free = Tr(ar: 'مجاني', en: 'Free', am: 'ነፃ');
  static const isNew = Tr(ar: 'جديد', en: 'NEW', am: 'አዲስ');
  static const audio = Tr(ar: 'صوت', en: 'Audio', am: 'ድምጽ');
  static const pages = Tr(ar: 'صفحة', en: 'pages', am: 'ገጾች');

  // ─── Lessons & Player ────────────────────────────────
  static const lessons = Tr(ar: 'الدروس', en: 'Lessons', am: 'ትምህርቶች');
  static const nowPlaying = Tr(
    ar: 'يُشغَّل الآن',
    en: 'NOW PLAYING',
    am: 'አሁን በመጫወት ላይ',
  );
  static const partN = Tr(ar: 'الجزء', en: 'Part', am: 'ክፍል');
  static const minutes = Tr(ar: 'دقيقة', en: 'min', am: 'ደቂቃ');
  static const speed = Tr(ar: 'السرعة', en: 'SPEED', am: 'ፍጥነት');

  // ─── Downloads ───────────────────────────────────────
  static const noDownloads = Tr(
    ar: 'لا توجد تحميلات بعد',
    en: 'No downloads yet',
    am: 'እስካሁን ውርዶች የሉም',
  );
  static const downloadsAppearHere = Tr(
    ar: 'الكتب والدروس التي تحملها ستظهر هنا',
    en: 'Books and lessons you download will appear here',
    am: 'ያወረዷቸው መጻሕፍት እና ትምህርቶች እዚህ ይታያሉ',
  );
  static const storageUsed = Tr(
    ar: 'المساحة المستخدمة',
    en: 'Storage Used',
    am: 'የተጠቀሙት ቦታ',
  );
  static const deleteAll = Tr(ar: 'حذف الكل', en: 'Delete All', am: 'ሁሉንም ሰርዝ');

  // ─── Settings ────────────────────────────────────────
  static const appearance = Tr(ar: 'المظهر', en: 'APPEARANCE', am: 'መልክ');
  static const about = Tr(ar: 'حول', en: 'ABOUT', am: 'ስለ');
  static const darkMode = Tr(ar: 'الوضع الداكن', en: 'Dark Mode', am: 'ጨለማ ሁነታ');
  static const language = Tr(ar: 'اللغة', en: 'Language', am: 'ቋንቋ');
  static const signOut = Tr(ar: 'تسجيل الخروج', en: 'Sign Out', am: 'ውጣ');
  static const islamicPlatform = Tr(
    ar: 'منصة تعلم إسلامية',
    en: 'Islamic learning platform',
    am: 'የእስልምና ትምህርት መድረክ',
  );
  static const version = Tr(ar: 'الإصدار', en: 'Version', am: 'ስሪት');
}
