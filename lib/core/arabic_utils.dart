/// Arabic language utilities for the app.
class ArabicUtils {
  /// Converts any positive integer to its Arabic ordinal.
  /// Works for any number — no maximum limit.
  /// Examples:
  ///   1  → الأول
  ///   21 → الحادي والعشرون
  ///   100 → المئة
  ///   500 → الخمسمئة
  static String ordinal(int n) {
    if (n <= 0) return '$n';

    // First 20 are irregular
    const irregular = [
      '', // 0 placeholder
      'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
      'الحادي عشر', 'الثاني عشر', 'الثالث عشر',
      'الرابع عشر', 'الخامس عشر', 'السادس عشر',
      'السابع عشر', 'الثامن عشر', 'التاسع عشر',
      'العشرون',
    ];

    if (n <= 20) return irregular[n];

    // Tens
    const tens = [
      '', '', 'العشرون', 'الثلاثون', 'الأربعون',
      'الخمسون', 'الستون', 'السبعون', 'الثمانون', 'التسعون',
    ];

    // Units for compound numbers (21-99)
    const units = [
      '', 'الحادي', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع',
    ];

    if (n < 100) {
      final unit = n % 10;
      final ten = n ~/ 10;
      if (unit == 0) return tens[ten];
      return '${units[unit]} و${tens[ten]}';
    }

    if (n == 100) return 'المئة';
    if (n < 200) return 'المئة و${ordinal(n - 100)}';
    if (n == 200) return 'المئتان';
    if (n < 1000) {
      final hundreds = n ~/ 100;
      final remainder = n % 100;
      const hundredsWords = [
        '', '', 'المئتان', 'الثلاثمئة', 'الأربعمئة',
        'الخمسمئة', 'الستمئة', 'السبعمئة', 'الثمانمئة',
        'التسعمئة',
      ];
      if (remainder == 0) return hundredsWords[hundreds];
      return '${hundredsWords[hundreds]} و${ordinal(remainder)}';
    }

    // For very large numbers just use the numeral
    return 'الجزء $n';
  }

  /// Returns lesson title for a given part number.
  /// Example: partNumber=8 → "الجزء الثامن"
  static String lessonTitle(int partNumber) {
    return 'الجزء ${ordinal(partNumber)}';
  }
}
