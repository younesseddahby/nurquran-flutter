/// UI strings, Arabic + English. The web app's i18n covers the same
/// keys; this is the subset the Flutter UI uses.
class S {
  final bool isAr;
  const S(this.isAr);

  static const arabic = S(true);
  static const english = S(false);

  String get appName => 'نور القرآن';
  String get home => isAr ? 'الرئيسية' : 'Home';
  String get quran => isAr ? 'القرآن' : 'Quran';
  String get mushaf => isAr ? 'المصحف' : 'Mushaf';
  String get bookmarks => isAr ? 'الفواصل' : 'Bookmarks';
  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get tafseer => isAr ? 'التفسير' : 'Tafseer';

  String get searchPlaceholder => isAr
      ? 'ابحث عن سورة أو آية أو كلمة…'
      : 'Search a surah, ayah or word…';
  String get continueReading => isAr ? 'متابعة القراءة' : 'Continue Reading';
  String get ayah => isAr ? 'الآية' : 'Ayah';
  String get popular => isAr ? 'سور مختارة' : 'Popular Surahs';
  String get viewAll => isAr ? 'عرض الكل' : 'View All';
  String get surahs => isAr ? 'السور' : 'Surahs';
  String get juzs => isAr ? 'الأجزاء' : 'Juzs';
  String get hizbs => isAr ? 'الأحزاب' : 'Hizbs';
  String get all => isAr ? 'الكل (١١٤)' : 'All (114)';
  String get meccan => isAr ? 'مكية (٨٦)' : 'Meccan (86)';
  String get medinan => isAr ? 'مدنية (٢٨)' : 'Medinan (28)';
  String get noResults => isAr ? 'لا توجد نتائج' : 'No results';
  String get searchBySurah => isAr
      ? 'ابحث باسم السورة أو رقمها…'
      : 'Search by surah name or number…';
  String get searchByJuz => isAr
      ? 'ابحث برقم الجزء أو اسم السورة…'
      : 'Search by Juz number or surah name…';
  String get searchByHizb => isAr
      ? 'ابحث برقم الحزب أو اسم السورة…'
      : 'Search by Hizb number or surah name…';
  String get juz => isAr ? 'الجزء' : 'Juz';
  String get hizb => isAr ? 'الحزب' : 'Hizb';
  String get verses => isAr ? 'آية' : 'verses';
  String get surah => isAr ? 'سورة' : 'Surah';
  String get page => isAr ? 'صفحة' : 'Page';
  String get backToList => isAr ? 'العودة إلى القائمة' : 'Back to list';
  String get previous => isAr ? 'السابقة' : 'Previous';
  String get next => isAr ? 'التالية' : 'Next';
  String get showTafseer => isAr ? 'التفسير' : 'Tafseer';
  String get noMatches => isAr ? 'لا توجد آيات مطابقة' : 'No matching ayahs';
  String get searchInSurah => isAr
      ? 'ابحث في السورة برقم الآية أو كلمة…'
      : 'Search in this surah by ayah number or word…';

  String get saveAyah => isAr ? 'حفظ الآية' : 'Save Ayah';
  String get removeAyah => isAr ? 'إزالة الفاصل' : 'Remove Bookmark';
  String get shareAyah => isAr ? 'مشاركة الآية' : 'Share Ayah';
  String get shareTitle => isAr ? 'مشاركة الآية' : 'Share Ayah';

  String get noBookmarks => isAr
      ? 'لا توجد فواصل بعد — اضغط على آية لحفظها هنا'
      : 'No bookmarks yet — tap an ayah to save it here';
  String get browseQuran => isAr ? 'تصفح القرآن' : 'Browse Quran';

  String get reading => isAr ? 'القراءة' : 'Reading';
  String get mushafSetting => isAr ? 'الرواية' : 'Mushaf';
  String get mushafDesc => isAr
      ? 'ورش عن نافع أو حفص عن عاصم'
      : 'Warsh or Hafs recitation';
  String get warsh => isAr ? 'ورش عن نافع' : "Warsh 'an Nafi'";
  String get hafs => isAr ? 'حفص عن عاصم' : "Hafs 'an Asim";
  String get navigationStyle => isAr ? 'طريقة التصفح' : 'Navigation Style';
  String get navigationStyleDesc => isAr
      ? 'صفحات المصحف أو التمرير المستمر'
      : 'Mushaf pages or continuous scrolling';
  String get pagesMode => isAr ? 'صفحات المصحف (٦٠٤)' : 'Mushaf Pages (604)';
  String get scrollingMode => isAr ? 'التمرير المستمر' : 'Continuous Scroll';
  String get showTajweed => isAr ? 'أحكام التجويد الملونة' : 'Tajweed Colors';
  String get showTajweedDesc => isAr
      ? 'تلوين أحكام التجويد في النص العربي'
      : 'Color tajweed rules in the Arabic text';
  String get language => isAr ? 'اللغة' : 'Language';
  String get readingLanguageAr =>
      isAr ? 'الواجهة والقراءة بالعربية' : 'Arabic interface & reading';
  String get readingLanguageEn =>
      isAr ? 'الواجهة والترجمة بالإنجليزية' : 'English interface & translation';
  String get appearance => isAr ? 'المظهر' : 'Appearance';
  String get themeSetting => isAr ? 'المظهر' : 'Theme';
  String get themeDesc =>
      isAr ? 'فاتح أو داكن' : 'Light or dark';
  String get lightTheme => isAr ? 'فاتح' : 'Light';
  String get darkTheme => isAr ? 'داكن' : 'Dark';
  String get typography => isAr ? 'الخط' : 'Typography';
  String get arabicSize => isAr ? 'حجم النص العربي' : 'Arabic Text Size';
  String get translationSize => isAr ? 'حجم الترجمة' : 'Translation Size';
  String get showTranslation => isAr ? 'إظهار الترجمة' : 'Show Translation';
  String get showTranslationDesc => isAr
      ? 'إظهار الترجمة الإنجليزية تحت الآيات'
      : 'Show the English translation under ayahs';
  String get more => isAr ? 'المزيد' : 'More';
  String get about => isAr ? 'عن التطبيق' : 'About';
  String get aboutText => isAr
      ? 'نور القرآن — قراءة القرآن الكريم بروايتي ورش وحفص، دون اتصال ودون إعلانات. النسخة المبنية بفلاتر.'
      : 'Nur Quran — read the Holy Quran in Warsh and Hafs, fully offline, no ads. Flutter build.';
  String get rateApp => isAr ? 'قيّم التطبيق' : 'Rate the App';
  String get rateAppDesc => isAr
      ? 'رأيك يساعدنا على التحسين'
      : 'Your feedback helps us improve';
  String get version => isAr ? 'الإصدار' : 'Version';

  String get mushafHafsNote => isAr
      ? 'صفحات المصحف برواية حفص — بدّل إلى التمرير لقراءة ورش'
      : 'Mushaf pages are in Hafs — switch to scrolling to read Warsh';
  String get tafseerTitle => isAr ? 'التفسير الميسر' : 'Tafseer Al-Muyassar';
  String get tafseerSubtitle => isAr
      ? 'تفسير آيات القرآن الكريم'
      : 'Explanation of the verses of the Holy Quran';
  String get tafseerSearch => isAr
      ? 'ابحث عن سورة…'
      : 'Search for a surah…';
  String get goToReading => isAr ? 'الذهاب إلى القراءة' : 'Go to Reading';
  String get jumpToPage => isAr ? 'الانتقال إلى صفحة' : 'Jump to Page';
  String get enterPageNumber =>
      isAr ? 'رقم الصفحة (١ – ٦٠٤)' : 'Page number (1 – 604)';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get go => isAr ? 'انتقال' : 'Go';
  String juzStart(int ayah, int h1, int h2) => isAr
      ? 'بداية الجزء — الآية $ayah · الأحزاب $h1 و $h2'
      : 'Start — Ayah $ayah · Hizbs $h1 & $h2';
  String hizbStart(int ayah, int juz) => isAr
      ? 'الآية $ayah · الجزء $juz'
      : 'Ayah $ayah · Juz $juz';
}
