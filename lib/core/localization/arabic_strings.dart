import 'arabic_numerals.dart';
import 'arabic_formatting.dart';
import '../quran/portion_unit.dart';

class ArabicStrings {
  const ArabicStrings._();

  // --- 003 mushaf ---
  static const mushafTitle = 'المصحف';
  static const readNowAction = 'اقرأ الآن';
  static const assignmentDetailsAction = 'تفاصيل الورد';
  static const completeReadingAction = 'تمت القراءة';
  static const mushafIndexAction = 'الفهرس';
  static const surahsTab = 'السور';
  static const ajzaaTab = 'الأجزاء';
  static const ahzabTab = 'الأحزاب';
  static const pagesTab = 'الصفحات';
  static const bookmarksTitle = 'العلامات';
  static const bookmarksEmpty = 'لا توجد علامات محفوظة بعد';
  static const addBookmarkAction = 'إضافة علامة';
  static const bookmarkNoteHint = 'ملاحظة اختيارية';
  static const bookmarkSaved = 'أضيفت العلامة';
  static const mushafLoadError = 'تعذر تحميل المصحف';
  static const mushafIntegrityError = 'تعذر التحقق من ملفات المصحف';
  static const surahSearchHint = 'ابحث عن سورة';
  static const pageNumberLabel = 'الصفحة';
  static const juzLabel = 'الجزء';
  static const mushafLicensesTitle = 'مصادر المصحف والتراخيص';
  static const kfgqpcAttribution =
      'النص والخط: مجمع الملك فهد لطباعة المصحف الشريف (KFGQPC).';
  static const tanzilAttribution = 'بيانات الصفحات والأجزاء: Tanzil.';
  static const khatmDuaTitle = 'دعاء ختم القرآن';
  static const deleteBookmarkAction = 'حذف العلامة';
  static const bookmarksEmptyHint =
      'يمكنك حفظ علامات أثناء القراءة للرجوع إليها لاحقًا';
  static const versionLabel = 'الإصدار';
  static const sourceLinkLabel = 'رابط المصدر';
  static const licenseLabel = 'الترخيص';
  static const kfgqpcSourceName = 'مجمع الملك فهد لطباعة المصحف الشريف';
  static const kfgqpcVersion = 'الإصدار ٢٢';
  static const kfgqpcLink = 'https://qul.tarteel.ai/resources/quran-script/86';
  static const kfgqpcLicense = 'استخدام مجاني للنصوص والخطوط دون تعديل';
  static const tanzilSourceName = 'مشروع تنزيل (Tanzil.net)';
  static const tanzilVersion = 'الإصدار ١.٠';
  static const tanzilLink = 'https://tanzil.net';
  static const tanzilLicense = 'المشاع الإبداعي نَسب المُصنّف (CC-BY 3.0)';
  static const ayahWord = 'آية';
  static const surahWord = 'سورة';
  static String portionPageProgress(int current, int total) =>
      'صفحة ${ArabicNumerals.format(current)} من ${ArabicNumerals.format(total)}';
  static String surahAyahMeta(int page, int ayahs) =>
      'صفحة ${ArabicNumerals.format(page)} · ${ArabicNumerals.format(ayahs)} آيات';
  static String juzHizbMeta(String surahName, int page) =>
      'سورة $surahName · صفحة ${ArabicNumerals.format(page)}';
  // --- 006 reminders ---
  static const reminderPermissionExplain =
      '\u{62a}\u{64f}\u{633}\u{62a}\u{62e}\u{62f}\u{645}\u{20}\u{627}\u{644}\u{625}\u{634}\u{639}\u{627}\u{631}\u{627}\u{62a}\u{20}\u{644}\u{62a}\u{630}\u{643}\u{64a}\u{631}\u{643}\u{20}\u{628}\u{648}\u{631}\u{62f}\u{643}\u{20}\u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}\u{60c}\u{20}\u{648}\u{64a}\u{64f}\u{62d}\u{633}\u{628}\u{20}\u{645}\u{648}\u{639}\u{62f}\u{647}\u{627}\u{20}\u{639}\u{644}\u{649}\u{20}\u{62c}\u{647}\u{627}\u{632}\u{643}\u{2e}';
  static const reminderPermissionTitle =
      '\u{62a}\u{641}\u{639}\u{64a}\u{644}\u{20}\u{62a}\u{630}\u{643}\u{64a}\u{631}\u{627}\u{62a}\u{20}\u{627}\u{644}\u{648}\u{631}\u{62f}';
  static const reminderActivate =
      '\u{62a}\u{641}\u{639}\u{64a}\u{644}\u{20}\u{627}\u{644}\u{62a}\u{630}\u{643}\u{64a}\u{631}\u{627}\u{62a}';
  static const reminderPermissionContinue =
      '\u{645}\u{62a}\u{627}\u{628}\u{639}\u{629}';
  static const reminderPermissionLater =
      '\u{644}\u{64a}\u{633}\u{20}\u{627}\u{644}\u{622}\u{646}';
  static const reminderPermissionDenied =
      '\u{644}\u{645}\u{20}\u{62a}\u{64f}\u{641}\u{639}\u{651}\u{644}\u{20}\u{627}\u{644}\u{625}\u{634}\u{639}\u{627}\u{631}\u{627}\u{62a}\u{2e}\u{20}\u{64a}\u{645}\u{643}\u{646}\u{643}\u{20}\u{62a}\u{641}\u{639}\u{64a}\u{644}\u{647}\u{627}\u{20}\u{645}\u{646}\u{20}\u{625}\u{639}\u{62f}\u{627}\u{62f}\u{627}\u{62a}\u{20}\u{627}\u{644}\u{62c}\u{647}\u{627}\u{632}\u{2e}';
  static const cityCairo = '\u{627}\u{644}\u{642}\u{627}\u{647}\u{631}\u{629}';
  static const cityAlexandria =
      '\u{627}\u{644}\u{625}\u{633}\u{643}\u{646}\u{62f}\u{631}\u{64a}\u{629}';
  static const cityMakkah =
      '\u{645}\u{643}\u{629}\u{20}\u{627}\u{644}\u{645}\u{643}\u{631}\u{645}\u{629}';
  static const cityMadinah =
      '\u{627}\u{644}\u{645}\u{62f}\u{64a}\u{646}\u{629}\u{20}\u{627}\u{644}\u{645}\u{646}\u{648}\u{631}\u{629}';
  static const cityRiyadh = '\u{627}\u{644}\u{631}\u{64a}\u{627}\u{636}';
  static const cityAmman = '\u{639}\u{645}\u{651}\u{627}\u{646}';
  static const cityJerusalem = '\u{627}\u{644}\u{642}\u{62f}\u{633}';
  static const cityDoha = '\u{627}\u{644}\u{62f}\u{648}\u{62d}\u{629}';
  static const cityDubai = '\u{62f}\u{628}\u{64a}';
  static const cityKuwait = '\u{627}\u{644}\u{643}\u{648}\u{64a}\u{62a}';
  static const cityBeirut = '\u{628}\u{64a}\u{631}\u{648}\u{62a}';
  static const cityDamascus = '\u{62f}\u{645}\u{634}\u{642}';
  static const cityBaghdad = '\u{628}\u{63a}\u{62f}\u{627}\u{62f}';
  static const cityAbuDhabi = '\u{623}\u{628}\u{648} \u{638}\u{628}\u{64a}';
  static const remindersTitle = 'التذكيرات';
  static const reminderNotificationTitle = 'وردك اليوم';
  static const reminderTestTitle = 'تذكير تجريبي';
  static const reminderTestBody = 'هذا تذكير تجريبي لمتابعة وردك اليوم.';
  static const reminderListSeparator = '، ';
  static const reminderMessageSeparator = ' — ';
  static const reminderChannelName =
      '\u{62a}\u{630}\u{643}\u{64a}\u{631}\u{627}\u{62a} \u{627}\u{644}\u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}';
  static const reminderChannelDescription =
      '\u{62a}\u{630}\u{643}\u{64a}\u{631}\u{627}\u{62a} \u{645}\u{62d}\u{644}\u{64a}\u{629} \u{628}\u{645}\u{648}\u{639}\u{62f} \u{627}\u{644}\u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}';
  static String reminderPortionInGroup(String portion, String group) =>
      '$portion في $group';
  static const reminderFajr = 'بعد الفجر';
  static const reminderAsr = 'بعد العصر';
  static const reminderNight = 'تذكير المساء';
  static const reminderOffset = 'دقيقة بعد الصلاة';
  static const reminderNightTime = 'وقت التذكير المسائي';
  static const reminderTest = 'إرسال تذكير تجريبي';
  static const reminderGroupTitle = 'تذكيرات المجموعة';
  static const reminderGroupMessage = 'رسالة اختيارية للمجموعة';
  static const reminderMute = 'كتم هذا التذكير على هذا الجهاز';
  static const reminderMuteGroup = 'كتم تذكيرات المجموعة على هذا الجهاز';
  static const reminderPermissionHelp =
      'فعّل الإشعارات من إعدادات الجهاز لتصلك التذكيرات.';
  static const reminderCalculationMethod = 'طريقة حساب مواقيت الصلاة';
  static const reminderLocation = 'موقع مواقيت الصلاة';
  static const reminderEgyptMethod = 'الهيئة المصرية العامة للمساحة';
  static const reminderUmmAlQuraMethod = 'أم القرى';
  static const reminderMwlMethod = 'رابطة العالم الإسلامي';
  static const reminderKarachiMethod = 'جامعة العلوم الإسلامية بكراتشي';
  static const reminderIsnaMethod = 'الاتحاد الإسلامي بأمريكا الشمالية';
  static const reminderCityFallback = 'اختر مدينة';
  static const reminderLocationExplanation =
      'يُستخدم موقعك لحساب مواقيت الصلاة على جهازك فقط.';
  static const reminderSave = 'حفظ التذكيرات';
  static const reminderOwnerOnly = 'يمكن لمالك المجموعة تعديل هذا الجدول.';
  static const reminderMessageLimit = 'حتى ٨٠ حرفًا';

  // --- 008 admin ---
  static const adminEntry = 'لوحة الإدارة';
  static const adminTitle = 'إدارة التطبيق';
  static const adminGroups = 'المجموعات';
  static const adminUsers = 'المستخدمون';
  static const adminAudit = 'سجل الإجراءات';
  static const adminOffline = 'تحتاج لوحة الإدارة إلى اتصال بالإنترنت. تحقق من الاتصال ثم أعد المحاولة.';
  static const adminLoadError = 'تعذر تحميل البيانات. تحقق من الاتصال والصلاحية ثم أعد المحاولة.';
  static const adminEmpty = 'لا توجد نتائج مطابقة. غيّر البحث أو التصفية.';
  static const adminSearch = 'ابحث بالاسم أو البريد';
  static const adminAllStatuses = 'كل الحالات';
  static const adminRefresh = 'إعادة المحاولة';
  static const adminTotalUsers = 'إجمالي المستخدمين';
  static const adminNewUsers = 'مستخدمون جدد خلال ٧ أيام';
  static const adminNewUsers30 = 'مستخدمون جدد خلال ٣٠ يومًا';
  static const adminActiveToday = 'نشطون اليوم';
  static const adminTotalGroups = 'إجمالي المجموعات';
  static const adminFormingGroups = 'مجموعات قيد التكوين';
  static const adminActiveGroups = 'مجموعات نشطة';
  static const adminArchivedGroups = 'مجموعات مؤرشفة';
  static const adminTodayRate = 'إنجاز اليوم';
  static const adminKhatmas = 'الختمات المكتملة خلال ٣٠ يومًا';
  static const adminKhatmas7 = 'ختمات آخر ٧ أيام';
  static const adminLast30Days = 'إنجازات آخر ٣٠ يومًا';
  static const adminGroupDetail = 'تفاصيل المجموعة';
  static const adminUserDetail = 'تفاصيل المستخدم';
  static const adminArchive = 'أرشف المجموعة';
  static const adminRestore = 'استعد المجموعة';
  static const adminDelete = 'احذف نهائيًا';
  static const adminDeleteConfirm = 'اكتب اسم المجموعة للتأكيد';
  static const adminDeleteUserConfirm = 'هل تريد حذف الحساب نهائيًا؟';
  static const adminRemoveMember = 'أزل العضو';
  static const adminTransferOwner = 'نقل الملكية';
  static const adminRegenerateInvite = 'ولّد رمز دعوة جديدًا';
  static const adminSuspend = 'أوقف الحساب';
  static const adminUnsuspend = 'ألغِ الإيقاف';
  static const adminSuspendedStatus = 'موقوف';
  static const adminResetPassword = 'أعد تعيين كلمة المرور';
  static const adminCreateUser = 'أنشئ مستخدمًا';
  static const adminGrantAdmin = 'امنح صلاحية الإدارة';
  static const adminRevokeAdmin = 'اسحب صلاحية الإدارة';
  static const adminCreateUserTitle = 'إنشاء حساب';
  static const adminDisplayName = 'الاسم الظاهر';
  static const adminEmail = 'البريد الإلكتروني';
  static const adminPassword = 'كلمة المرور';
  static const adminSuspendedSignIn = 'أُوقف هذا الحساب مؤقتًا. تواصل مع مسؤول التطبيق للمساعدة.';
  static const adminSuccessResult = 'نجح';
  static const adminFailureResult = 'تعذر';
  static const adminOwnerRole = 'المالك';
  static const adminSupervisorRole = 'مشرف';
  static const adminMemberRole = 'عضو';
  static const adminJuzUnit = 'جزء';

  // --- 005 home ---
  static const homeTab = 'الرئيسية';
  static const groupsTab = 'مجموعاتي';
  static const mushafTab = 'المصحف';
  static const profileTab = 'حسابي';
  static const todayTitle = 'وردك اليوم';
  static String homeGreeting(String? displayName) {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty) return 'السلام عليكم';
    final nameParts = name.split(RegExp(r'\s+'));
    return 'السلام عليكم يا ${name.length > 18 ? nameParts.first : name}';
  }
  static const otherGroupsTitle = 'أوراد مجموعاتك الأخرى';
  static const todayCompleteTitle = 'أتممت وردك اليوم';
  static const setMainGroupAction = 'اجعلها مجموعتي الرئيسية';
  static const portionCompleteAction = 'تمت القراءة';
  static const portionUndoAction = 'تراجع عن الإتمام';
  static const todayLoadError = 'تعذر تحميل وردك اليوم';
  static const homeEmptyTitle = 'ابدأ وردك مع مجموعة';
  static const openGroupAction = 'افتح المجموعة';
  static const joinByInviteAction = 'أدخل رمز الدعوة';
  static const settingsTooltip = 'الإعدادات';
  static const hijriDateUnavailable = 'التاريخ الهجري غير متاح';
  // --- end 005 home ---
  // --- spec 002 Google sign-in ---
  static const googleSignIn = 'تسجيل الدخول باستخدام Google';
  static const googleSignInHint =
      'إذا كنت مسجلاً عبر Google فاستخدم زر Google.';
  static const or = 'أو';

  // --- US1 dashboard ---
  static const myWirdToday = 'وردك اليوم';
  static const availableJuzTitle = 'أجزاء متاحة للتطوع';
  static const fullKhatmaBanner = 'اكتملت الختمة اليوم';
  static const khatmaDuaNote = 'يُستحب دعاء الختم بعد إتمام الجزء الثلاثين';
  static const dashboardLoadError = 'تعذر تحميل لوحة المجموعة';
  static const networkFailure = 'تحقق من الاتصال ثم أعد المحاولة';
  static const noAssignmentToday = 'لا يوجد ورد مسند إليك اليوم';
  static const openTodayWird = 'افتح وردك';
  static const activeMembersCount = 'الأعضاء النشطون';
  static const formingDashboard = 'المجموعة في طور التكوين';
  static const memberSeats = 'مقاعد الأعضاء';
  // --- Main design pass: dashboard and group list copy ---
  static const juzGridTitle = 'الأجزاء';
  static const groupsHeaderSubtitle = 'وردكم اليومي يبدأ بخطوة معًا';
  static const groupShortcutsTitle = 'طرق سريعة للانضمام';
  static String membersProgress(int members) =>
      '${ArabicNumerals.format(members)} من ${ArabicNumerals.format(30)} عضوًا';
  static const assignmentGroupDate = 'ورد اليوم';

  static const appName = '\u{62d}\u{644}\u{642}\u{629}';
  static const signInHint = 'ختمة القرآن مع حلقتك، وردٌ كل يوم';
  static const signInError =
      '\u{62a}\u{639}\u{630}\u{631} \u{62a}\u{633}\u{62c}\u{64a}\u{644} \u{627}\u{644}\u{62f}\u{62e}\u{648}\u{644}. \u{62d}\u{627}\u{648}\u{644} \u{645}\u{631}\u{629} \u{623}\u{62e}\u{631}\u{649}.';
  static const loading =
      '\u{62c}\u{627}\u{631}\u{64a} \u{627}\u{644}\u{62a}\u{62d}\u{645}\u{64a}\u{644}...';
  static const retry =
      '\u{625}\u{639}\u{627}\u{62f}\u{629} \u{627}\u{644}\u{645}\u{62d}\u{627}\u{648}\u{644}\u{629}';
  static const refresh = '\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}';
  static const save = '\u{62d}\u{641}\u{638}';
  static const cancel = '\u{625}\u{644}\u{63a}\u{627}\u{621}';
  static const back = '\u{631}\u{62c}\u{648}\u{639}';
  static const open = '\u{641}\u{62a}\u{62d}';
  static const createGroup =
      '\u{625}\u{646}\u{634}\u{627}\u{621} \u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const discoverGroups =
      '\u{627}\u{643}\u{62a}\u{634}\u{627}\u{641} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{627}\u{62a} \u{627}\u{644}\u{639}\u{627}\u{645}\u{629}';
  static const pendingApproval =
      '\u{628}\u{627}\u{646}\u{62a}\u{638}\u{627}\u{631} \u{627}\u{644}\u{642}\u{628}\u{648}\u{644} \u{645}\u{646} \u{645}\u{627}\u{644}\u{643} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const groupSelectionTitle =
      '\u{645}\u{62c}\u{645}\u{648}\u{639}\u{627}\u{62a}\u{64a}';
  static const dashboardTitle =
      '\u{645}\u{62a}\u{627}\u{628}\u{639}\u{629} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const assignmentDetailTitle =
      '\u{648}\u{631}\u{62f}\u{643} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const organizerReviewTitle =
      '\u{645}\u{631}\u{627}\u{62c}\u{639}\u{629} \u{62a}\u{648}\u{632}\u{64a}\u{639} \u{627}\u{644}\u{623}\u{62c}\u{632}\u{627}\u{621}';
  static const joinRequestsTitle =
      '\u{637}\u{644}\u{628}\u{627}\u{62a} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}';
  static const memberManagementTitle =
      '\u{625}\u{62f}\u{627}\u{631}\u{629} \u{627}\u{644}\u{623}\u{639}\u{636}\u{627}\u{621}';
  static const historyTitle =
      '\u{633}\u{62c}\u{644} \u{627}\u{644}\u{62e}\u{62a}\u{645}\u{627}\u{62a} \u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}\u{629}';
  static const settingsTitle =
      '\u{627}\u{644}\u{625}\u{639}\u{62f}\u{627}\u{62f}\u{627}\u{62a}';
  static const completed =
      '\u{62a}\u{645}\u{62a} \u{627}\u{644}\u{642}\u{631}\u{627}\u{621}\u{629}';
  static const pending = 'لم يُقرأ بعد';
  static const missed = 'فائت';
  static const late = 'قُرئ متأخرًا';

  /// Constitution v2.4.0 statuses.
  static const available = 'متاح';
  static const unread = 'لم يقرأه أحد';

  /// Juz semantics: 'الجزء' + ordinal digit, and the mine marker 'جزؤك'.
  static const partLabel = 'الجزء';
  static const mineSuffix = 'جزؤك';

  static const showPassword = 'إظهار كلمة المرور';
  static const hidePassword = 'إخفاء كلمة المرور';

  // --- Juz ordinal names (UI copy, not Quran text; T043) ---
  static const List<String> juzOrdinals = [
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
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];

  /// الاسم الترتيبي للجزء (١..٣٠).
  static String juzName(int n) => juzOrdinals[n - 1];

  /// نطاق القراءة: "من سورة {س} آية {ن} إلى سورة {م} آية {ك}".
  static String juzRange({
    required String startSura,
    required int startAya,
    required String endSura,
    required int endAya,
  }) {
    return 'من سورة $startSura آية ${_num(startAya)}'
        ' إلى سورة $endSura آية ${_num(endAya)}';
  }

  static String _num(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  // --- Role markers ---
  static const roleOwner = 'المالك';
  static const roleSupervisor = 'مشرف';
  static const roleMember = 'عضو';

  // --- Auth entry screen (spec 002) ---
  static const signInTitle = 'تسجيل الدخول';
  static const createAccountTitle = 'إنشاء حساب';
  static const emailLabel = 'البريد الإلكتروني';
  static const passwordLabel = 'كلمة المرور';
  static const confirmPasswordLabel = 'تأكيد كلمة المرور';
  static const displayNameLabel = 'الاسم الظاهر';
  static const passwordHint = '٨ أحرف على الأقل';
  static const forgotPasswordGuidance =
      'نسيت كلمة المرور؟ تواصل مع مسؤول التطبيق لتعيين كلمة جديدة.';
  static const checkingSession = 'جارٍ التحقق من جلستك';
  static const profileLoadTitle = 'تعذر تحميل ملفك الشخصي';

  // --- Group lifecycle copy (S1/S4/S9/S5-forming) ---
  static const nameLengthError = 'اسم المجموعة من ٣ إلى ٦٠ حرفًا';
  static const descriptionLengthError = 'الوصف حتى ٢٠٠ حرف';
  static const ownerGroupLimitCopy =
      'يمتلك حسابك ٣ مجموعات بالفعل. أرشف مجموعة أولًا لإنشاء مجموعة جديدة.';
  static const groupsNeedMembersEntry =
      'تصفّح الحلقات المتاحة أو أنشئ حلقة جديدة.';
  static const joinAnyGroupAction = 'انضم لأي مجموعة ناقصة';
  static const iHaveInviteLink = 'عندي رابط دعوة';
  static const searchGroupAction = 'ابحث عن مجموعة';
  static const createTheGroup = 'أنشئ المجموعة';
  static const formingLabel = 'قيد التكوين';
  static const activeLabel = 'نشطة';
  static const startKhatmaAction = 'ابدأ الختمة';
  static const shareInviteAction = 'شارك الدعوة';
  static const inviteCodeLabel = 'رمز الدعوة';
  static const showInviteCode = 'إظهار الرمز';
  static const startJuzChoice = 'اختر جزء البداية للمقعد ١';
  static const settingsApplyTomorrowNote =
      'تغييرات التوقيت تُطبق من يوم المجموعة التالي';
  static const archiveGroupAction = 'أرشف المجموعة';
  static const missingX = 'ناقص';

  // --- T114 design-system compliance: group lifecycle screens ---
  static const publicVisibility = 'عامة';
  static const privateVisibility = 'خاصة';
  static const groupVisibilityTitle = 'ظهور الحلقة';
  static const joinModeTitle = 'طريقة الانضمام';
  static const autoAcceptJoinMode = 'قبول تلقائي';
  static const ownerApprovalJoinMode = 'بموافقة المالك';
  static const publicVisibilityHint =
      'يمكن للجميع العثور على الحلقة وطلب الانضمام.';
  static const privateVisibilityHint =
      'لا تظهر في البحث؛ ينضم الأعضاء برمز الدعوة.';
  static const autoAcceptJoinModeHint = 'ينضم العضو مباشرةً عند توفر مقعد.';
  static const ownerApprovalJoinModeHint = 'تراجع طلب الانضمام قبل قبول العضو.';
  static const inviteShareMessage =
      'انضم إلى مجموعتي في ختمة يومية! رمز الدعوة: ';
  static const regenerateInviteAction = 'توليد رمز جديد';
  static const regenerateInviteTitle = 'توليد رمز دعوة جديد؟';
  static const regenerateInviteMessage =
      'سيتوقف عمل رمز الدعوة القديم ولن يعود رابط الدعوة السابق.';
  static const regenerateInviteConfirm = 'نعم، ولّد رمزًا جديدًا';
  static const archiveGroupTitle = 'أرشف المجموعة؟';
  static const archiveGroupMessage =
      'لن تُقبل انضمامات جديدة ولن تتولد أيام جديدة للمجموعة.';
  static const archiveGroupConfirm = 'نعم، أرشف';
  static const formingInviteSnack = 'رمز الدعوة: ';
  static const formingStartHint =
      'يمكنك بدء الختمة الآن، وتظهر أجزاء المقاعد الشاغرة «متاحة» للتطوع.';
  static const vacantSeat = 'مقعد شاغر';
  static const moreVacantSeats = 'مقاعد شاغرة أخرى';

  // --- US4 discovery and invitation screens ---
  static const discoveryScreenTitle =
      '\u{627}\u{643}\u{62a}\u{634}\u{627}\u{641} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{627}\u{62a}';
  static const inviteJoinScreenTitle = 'انضم لأي حلقة';
  static const noGroupAvailable =
      'لا توجد حلقة متاحة الآن. أعد المحاولة لاحقًا أو ابحث عن حلقة.';
  static const joinedAnyGroup = 'انضممت إلى الحلقة بنجاح.';
  static const joinGroupAction =
      '\u{627}\u{646}\u{636}\u{645} \u{625}\u{644}\u{649} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const joinedSuccessfully =
      '\u{62a}\u{645} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645} \u{625}\u{644}\u{649} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const previewInviteAction =
      '\u{639}\u{631}\u{636} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const inviteCodeInvalid =
      '\u{62a}\u{62d}\u{642}\u{642} \u{645}\u{646} \u{631}\u{645}\u{632} \u{627}\u{644}\u{62f}\u{639}\u{648}\u{629} \u{648}\u{623}\u{639}\u{62f} \u{627}\u{644}\u{645}\u{62d}\u{627}\u{648}\u{644}\u{629}.';
  static const discoveryOffline =
      '\u{64a}\u{644}\u{632}\u{645} \u{627}\u{62a}\u{635}\u{627}\u{644} \u{62a}\u{646}\u{638}\u{64a}\u{645}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{627}\u{62a}.';
  static const inviteUnavailable =
      '\u{644}\u{627} \u{64a}\u{645}\u{643}\u{646} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645} \u{625}\u{644}\u{649} \u{647}\u{630}\u{647} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{627}\u{644}\u{622}\u{646}.';
  static const groupArchivedLabel =
      '\u{645}\u{623}\u{631}\u{634}\u{641}\u{629}';
  static const activeMemberCountLabel =
      '\u{639}\u{636}\u{648} \u{646}\u{634}\u{637}';
  static const groupTimezoneLabel =
      '\u{627}\u{644}\u{62a}\u{648}\u{642}\u{64a}\u{62a} \u{627}\u{644}\u{645}\u{62d}\u{644}\u{64a}';
  static const joinError =
      '\u{62a}\u{639}\u{630}\u{631} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}. \u{62a}\u{62d}\u{642}\u{642} \u{645}\u{646} \u{627}\u{644}\u{627}\u{62a}\u{635}\u{627}\u{644} \u{648}\u{623}\u{639}\u{62f} \u{627}\u{644}\u{645}\u{62d}\u{627}\u{648}\u{644}\u{629}.';

  // Field-level validation copy.
  static const invalidEmailError = 'أدخل بريدًا إلكترونيًا صحيحًا';
  static const shortPasswordError = 'كلمة المرور ٨ أحرف على الأقل';
  static const passwordMismatchError = 'كلمتا المرور غير متطابقتين';
  static const displayNameError = 'أدخل اسمًا ظاهرًا (حتى ١٠٠ حرف)';
  static const requiredFieldError = 'هذا الحقل مطلوب';

  /// Maps backend/stable error codes to non-revealing Arabic copy that
  /// names the next action (spec 002 error contract).
  static String authError(String code) {
    switch (code) {
      case 'membership_limit':
        return membershipLimitMessage;
      case 'no_group_available':
        return noGroupAvailable;
      case 'invalid_credentials':
        return 'تحقق من البريد الإلكتروني وكلمة المرور، أو تواصل مع مسؤول التطبيق. $googleSignInHint';
      case 'suspended':
        return adminSuspendedSignIn;
      case 'google_auth_failed':
        return 'تعذر تسجيل الدخول باستخدام Google. أعد المحاولة أو استخدم البريد الإلكتروني.';
      case 'email_exists':
        return 'هذا البريد مسجل بالفعل. سجّل الدخول أو تواصل مع مسؤول التطبيق.';
      case 'network':
        return 'تعذر الاتصال بالخدمة. تحقق من الإنترنت وأعد المحاولة.';
      case 'rate_limited':
        return 'محاولات كثيرة، انتظر قليلًا ثم أعد المحاولة.';
      case 'missing_profile':
        return 'تعذر تحميل ملفك الشخصي. أعد المحاولة أو تواصل مع مسؤول التطبيق.';
      case 'validation_failed':
        return 'تحقق من البيانات المدخلة ثم أعد المحاولة.';
      case 'password_mismatch':
        return passwordMismatchError;
      default:
        return 'حدث خطأ غير متوقع. أعد المحاولة، وإن تكرر تواصل مع مسؤول التطبيق.';
    }
  }

  static const completeAction =
      '\u{62a}\u{623}\u{643}\u{64a}\u{62f} \u{625}\u{62a}\u{645}\u{627}\u{645} \u{627}\u{644}\u{62c}\u{632}\u{621}';
  static const undoAction =
      '\u{62a}\u{631}\u{627}\u{62c}\u{639} \u{639}\u{646} \u{627}\u{644}\u{625}\u{62a}\u{645}\u{627}\u{645}';
  static const offlineStale =
      '\u{623}\u{646}\u{62a} \u{62a}\u{639}\u{631}\u{636} \u{628}\u{64a}\u{627}\u{646}\u{627}\u{62a} \u{645}\u{62d}\u{641}\u{648}\u{638}\u{629}. \u{642}\u{62f} \u{644}\u{627} \u{62a}\u{643}\u{648}\u{646} \u{645}\u{62a}\u{627}\u{628}\u{639}\u{629} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{645}\u{62d}\u{62f}\u{62b}\u{629}.';
  static const noApprovedGroups = 'لم تنضم إلى حلقة بعد';
  static const noPublicGroups =
      '\u{644}\u{627} \u{62a}\u{648}\u{62c}\u{62f} \u{646}\u{62a}\u{627}\u{626}\u{62c} \u{645}\u{637}\u{627}\u{628}\u{642}\u{629}. \u{63a}\u{64a}\u{651}\u{631} \u{643}\u{644}\u{645}\u{627}\u{62a} \u{627}\u{644}\u{628}\u{62d}\u{62b} \u{623}\u{648} \u{627}\u{645}\u{633}\u{62d} \u{627}\u{644}\u{62a}\u{635}\u{641}\u{64a}\u{629}.';
  static const noJoinRequests = 'طلبات الانضمام بانتظارك';
  static const noJoinRequestsHint =
      'ستظهر هنا الطلبات الجديدة لتراجعها وتدير أعضاء الحلقة.';
  static const noPublishedCycle =
      '\u{644}\u{645} \u{64a}\u{646}\u{634}\u{631} \u{645}\u{627}\u{644}\u{643} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645} \u{628}\u{639}\u{62f}.';
  static const emptyHistory =
      '\u{644}\u{627} \u{62a}\u{648}\u{62c}\u{62f} \u{623}\u{64a}\u{627}\u{645} \u{633}\u{627}\u{628}\u{642}\u{629} \u{628}\u{639}\u{62f} \u{644}\u{647}\u{630}\u{647} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}.';
  static const groupFull =
      '\u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{645}\u{643}\u{62a}\u{645}\u{644}\u{629}. \u{644}\u{627} \u{64a}\u{645}\u{643}\u{646} \u{642}\u{628}\u{648}\u{644} \u{639}\u{636}\u{648} \u{62c}\u{62f}\u{64a}\u{62f} \u{642}\u{628}\u{644} \u{62a}\u{648}\u{641}\u{631} \u{645}\u{642}\u{639}\u{62f}.';
  static const publishBlocked =
      '\u{64a}\u{62c}\u{628} \u{623}\u{646} \u{62a}\u{636}\u{645} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} 30 \u{639}\u{636}\u{648}\u{627} \u{646}\u{634}\u{637}\u{627} \u{642}\u{628}\u{644} \u{646}\u{634}\u{631} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}.';
  static const noQuranReader =
      '\u{64a}\u{639}\u{631}\u{636} \u{627}\u{644}\u{62a}\u{637}\u{628}\u{64a}\u{642} \u{627}\u{633}\u{645} \u{627}\u{644}\u{62c}\u{632}\u{621} \u{648}\u{645}\u{62f}\u{627}\u{647} \u{641}\u{642}\u{637} \u{62f}\u{648}\u{646} \u{645}\u{635}\u{62d}\u{641} \u{62f}\u{627}\u{62e}\u{644}\u{64a}.';
  static const syncQueued =
      '\u{62a}\u{645} \u{62d}\u{641}\u{638} \u{627}\u{644}\u{625}\u{62c}\u{631}\u{627}\u{621} \u{648}\u{633}\u{62a}\u{62a}\u{645} \u{645}\u{632}\u{627}\u{645}\u{646}\u{62a}\u{647} \u{639}\u{646}\u{62f} \u{639}\u{648}\u{62f}\u{629} \u{627}\u{644}\u{627}\u{62a}\u{635}\u{627}\u{644}.';
  static const createGroupFailure =
      '\u{62a}\u{639}\u{630}\u{631} \u{625}\u{646}\u{634}\u{627}\u{621} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}. \u{631}\u{627}\u{62c}\u{639} \u{627}\u{644}\u{627}\u{633}\u{645} \u{648}\u{627}\u{644}\u{645}\u{646}\u{637}\u{642}\u{629} \u{627}\u{644}\u{632}\u{645}\u{646}\u{64a}\u{629} \u{62b}\u{645} \u{62d}\u{627}\u{648}\u{644} \u{645}\u{631}\u{629} \u{623}\u{62e}\u{631}\u{649}.';
  static const groupFajr =
      '\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{627}\u{644}\u{641}\u{62c}\u{631}';
  static const groupDailyWird =
      '\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{627}\u{644}\u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}';
  static const groupDailyDescription =
      '\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{639}\u{627}\u{645}\u{629} \u{644}\u{62e}\u{62a}\u{645} \u{627}\u{644}\u{642}\u{631}\u{622}\u{646} \u{64a}\u{648}\u{645}\u{64a}\u{627} \u{628}\u{62a}\u{648}\u{632}\u{64a}\u{639} \u{62c}\u{632}\u{621} \u{644}\u{643}\u{644} \u{639}\u{636}\u{648}.';
  static const todayCairoDate =
      '\u{627}\u{644}\u{64a}\u{648}\u{645}: 21 \u{64a}\u{648}\u{646}\u{64a}\u{648} 2026 - \u{62a}\u{648}\u{642}\u{64a}\u{62a} \u{627}\u{644}\u{642}\u{627}\u{647}\u{631}\u{629}';
  static const yourAssignment =
      '\u{648}\u{631}\u{62f}\u{643} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const part2 = '\u{62c}\u{632}\u{621} 2';
  static const partsStatusTitle =
      '\u{62d}\u{627}\u{644}\u{629} \u{627}\u{644}\u{623}\u{62c}\u{632}\u{627}\u{621}';
  static const partsStatusSubtitle =
      '\u{646}\u{638}\u{631}\u{629} \u{633}\u{631}\u{64a}\u{639}\u{629} \u{639}\u{644}\u{649} \u{643}\u{644} \u{623}\u{62c}\u{632}\u{627}\u{621} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const membersListTitle =
      '\u{642}\u{627}\u{626}\u{645}\u{629} \u{627}\u{644}\u{623}\u{639}\u{636}\u{627}\u{621}';
  static const membersListSubtitle =
      '\u{62d}\u{627}\u{644}\u{629} \u{639}\u{64a}\u{646}\u{629} \u{645}\u{646} \u{623}\u{639}\u{636}\u{627}\u{621} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const organizerActionsTitle =
      '\u{625}\u{62c}\u{631}\u{627}\u{621}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{627}\u{644}\u{643}';
  static const reviewAssignmentsAction =
      '\u{645}\u{631}\u{627}\u{62c}\u{639}\u{629} \u{627}\u{644}\u{62a}\u{648}\u{632}\u{64a}\u{639}';
  static const reviewJoinRequestsAction =
      '\u{637}\u{644}\u{628}\u{627}\u{62a} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}';
  static const manageMembersAction =
      '\u{625}\u{62f}\u{627}\u{631}\u{629} \u{627}\u{644}\u{623}\u{639}\u{636}\u{627}\u{621}';
  static const openHistoryAction =
      '\u{627}\u{644}\u{633}\u{62c}\u{644} \u{627}\u{644}\u{64a}\u{648}\u{645}\u{64a}';
  static const completedPartsMetric =
      '\u{627}\u{644}\u{623}\u{62c}\u{632}\u{627}\u{621} \u{627}\u{644}\u{645}\u{643}\u{62a}\u{645}\u{644}\u{629}';
  static const completionRateMetric =
      '\u{646}\u{633}\u{628}\u{629} \u{627}\u{644}\u{625}\u{62a}\u{645}\u{627}\u{645}';
  static const remainingPartsMetric =
      '\u{627}\u{644}\u{645}\u{62a}\u{628}\u{642}\u{64a}';
  static const latePartsMetric = '\u{645}\u{62a}\u{623}\u{62e}\u{631}';
  static const openAssignmentAction =
      '\u{641}\u{62a}\u{62d} \u{648}\u{631}\u{62f}\u{643}';
  static const statusLegendTitle =
      '\u{62f}\u{644}\u{64a}\u{644} \u{627}\u{644}\u{62d}\u{627}\u{644}\u{627}\u{62a}';
  static const activeMembersLabel =
      '\u{627}\u{644}\u{623}\u{639}\u{636}\u{627}\u{621} \u{627}\u{644}\u{646}\u{634}\u{637}\u{648}\u{646}';
  static const timezoneCairo =
      '\u{62a}\u{648}\u{642}\u{64a}\u{62a} \u{627}\u{644}\u{642}\u{627}\u{647}\u{631}\u{629}';
  static const lastSyncFiveMinutes =
      '\u{622}\u{62e}\u{631} \u{645}\u{632}\u{627}\u{645}\u{646}\u{629} \u{642}\u{628}\u{644} 5 \u{62f}\u{642}\u{627}\u{626}\u{642}';
  static const createPublicGroup =
      '\u{625}\u{646}\u{634}\u{627}\u{621} \u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{639}\u{627}\u{645}\u{629}';
  static const groupNameLabel =
      '\u{627}\u{633}\u{645} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const shortDescriptionLabel =
      '\u{648}\u{635}\u{641} \u{642}\u{635}\u{64a}\u{631}';
  static const timezoneLabel =
      '\u{627}\u{644}\u{645}\u{646}\u{637}\u{642}\u{629} \u{627}\u{644}\u{632}\u{645}\u{646}\u{64a}\u{629}';
  static const searchGroupLabel =
      '\u{627}\u{628}\u{62d}\u{62b} \u{628}\u{627}\u{633}\u{645} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const requestToJoin =
      '\u{637}\u{644}\u{628} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}';
  static const memberCount26 = '26 \u{639}\u{636}\u{648}';
  static const memberCount30 = '30 \u{639}\u{636}\u{648}';
  static const memberCount29 =
      '29 / 30 \u{639}\u{636}\u{648} \u{646}\u{634}\u{637}';
  static const requestFromYousef =
      '\u{637}\u{644}\u{628} \u{645}\u{646}: \u{64a}\u{648}\u{633}\u{641} \u{625}\u{628}\u{631}\u{627}\u{647}\u{64a}\u{645}';
  static const approve = '\u{642}\u{628}\u{648}\u{644}';
  static const reject = '\u{631}\u{641}\u{636}';
  static const groupReadiness =
      '\u{62c}\u{627}\u{647}\u{632}\u{64a}\u{629} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const groupOwner =
      '\u{645}\u{627}\u{644}\u{643} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const memberRole = '\u{639}\u{636}\u{648}';
  static const readyToPublish =
      '\u{62c}\u{627}\u{647}\u{632} \u{644}\u{644}\u{646}\u{634}\u{631}';
  static const swapPart =
      '\u{62a}\u{628}\u{62f}\u{64a}\u{644} \u{627}\u{644}\u{62c}\u{632}\u{621}';
  static const publishTodayWird =
      '\u{646}\u{634}\u{631} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static const textSizeLabel =
      '\u{62d}\u{62c}\u{645} \u{646}\u{635} \u{627}\u{644}\u{62c}\u{632}\u{621} \u{648}\u{627}\u{644}\u{645}\u{62f}\u{649}';
  static const selectedGroupCache =
      '\u{622}\u{62e}\u{631} \u{62d}\u{641}\u{638} \u{644}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{627}\u{644}\u{645}\u{62e}\u{62a}\u{627}\u{631}\u{629}: \u{642}\u{628}\u{644} 5 \u{62f}\u{642}\u{627}\u{626}\u{642}';
  static const signOut =
      '\u{62a}\u{633}\u{62c}\u{64a}\u{644} \u{627}\u{644}\u{62e}\u{631}\u{648}\u{62c}';
  static const noMissedParts =
      '\u{644}\u{627} \u{62a}\u{648}\u{62c}\u{62f} \u{623}\u{62c}\u{632}\u{627}\u{621} \u{641}\u{627}\u{626}\u{62a}\u{629}';
  static const threeMissedParts =
      '3 \u{623}\u{62c}\u{632}\u{627}\u{621} \u{641}\u{627}\u{626}\u{62a}\u{629}';
  static const oneLatePart =
      '\u{62c}\u{632}\u{621} \u{645}\u{643}\u{62a}\u{645}\u{644} \u{645}\u{62a}\u{623}\u{62e}\u{631}';
  static const june20 = '20 \u{64a}\u{648}\u{646}\u{64a}\u{648}';
  static const june19 = '19 \u{64a}\u{648}\u{646}\u{64a}\u{648}';
  static const june18 = '18 \u{64a}\u{648}\u{646}\u{64a}\u{648}';
  static const publicDiscoveryHint =
      '\u{62a}\u{638}\u{647}\u{631} \u{647}\u{646}\u{627} \u{627}\u{644}\u{645}\u{639}\u{644}\u{648}\u{645}\u{627}\u{62a} \u{627}\u{644}\u{639}\u{627}\u{645}\u{629} \u{641}\u{642}\u{637} \u{642}\u{628}\u{644} \u{627}\u{644}\u{642}\u{628}\u{648}\u{644}.';
  static const assignmentCompleteHint =
      '\u{623}\u{643}\u{651}\u{62f} \u{627}\u{644}\u{625}\u{62a}\u{645}\u{627}\u{645} \u{628}\u{639}\u{62f} \u{627}\u{644}\u{627}\u{646}\u{62a}\u{647}\u{627}\u{621} \u{645}\u{646} \u{642}\u{631}\u{627}\u{621}\u{629} \u{627}\u{644}\u{62c}\u{632}\u{621}.';
  static const undoCompletionHint =
      '\u{64a}\u{645}\u{643}\u{646}\u{643} \u{627}\u{644}\u{62a}\u{631}\u{627}\u{62c}\u{639} \u{625}\u{630}\u{627} \u{62a}\u{645} \u{627}\u{644}\u{62a}\u{623}\u{643}\u{64a}\u{62f} \u{628}\u{627}\u{644}\u{62e}\u{637}\u{623} \u{642}\u{628}\u{644} \u{625}\u{63a}\u{644}\u{627}\u{642} \u{627}\u{644}\u{64a}\u{648}\u{645}.';
  static const cacheStatusTitle =
      '\u{62d}\u{627}\u{644}\u{629} \u{627}\u{644}\u{62d}\u{641}\u{638} \u{627}\u{644}\u{645}\u{62d}\u{644}\u{64a}';
  static const rtlStatus =
      '\u{627}\u{644}\u{639}\u{631}\u{636} \u{627}\u{644}\u{62d}\u{627}\u{644}\u{64a} \u{639}\u{631}\u{628}\u{64a} \u{645}\u{646} \u{627}\u{644}\u{64a}\u{645}\u{64a}\u{646} \u{625}\u{644}\u{649} \u{627}\u{644}\u{64a}\u{633}\u{627}\u{631}';

  // US6 group management copy.
  static const overrideAssignmentTitle =
      '\u{625}\u{633}\u{646}\u{627}\u{62f} \u{627}\u{644}\u{62c}\u{632}\u{621}';
  static const overrideAssignmentAction = '\u{62a}\u{639}\u{64a}\u{64a}\u{646}';
  static const seatLabel = '\u{627}\u{644}\u{645}\u{642}\u{639}\u{62f}';
  static const operationFailed =
      '\u{62a}\u{639}\u{630}\u{631} \u{625}\u{62a}\u{645}\u{627}\u{645} \u{627}\u{644}\u{639}\u{645}\u{644}\u{64a}\u{629}. \u{62d}\u{627}\u{648}\u{644} \u{645}\u{631}\u{629} \u{623}\u{62e}\u{631}\u{649}.';
  static const roleChangeAction =
      '\u{62a}\u{63a}\u{64a}\u{64a}\u{631} \u{627}\u{644}\u{62f}\u{648}\u{631}';
  static const noActiveMembers =
      '\u{644}\u{627} \u{64a}\u{648}\u{62c}\u{62f} \u{623}\u{639}\u{636}\u{627}\u{621} \u{646}\u{634}\u{637}\u{648}\u{646} \u{641}\u{64a} \u{647}\u{630}\u{647} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}.';
  static const requestFromDiscovery = '\u{628}\u{62d}\u{62b}';
  static const requestFromInvite = '\u{62f}\u{639}\u{648}\u{629}';
  static const requestFromMatch = '\u{645}\u{648}\u{627}\u{641}\u{642}\u{629}';
  static const removeMemberAction =
      '\u{625}\u{632}\u{627}\u{644}\u{629} \u{627}\u{644}\u{639}\u{636}\u{648}';
  static const approveRequestAction =
      '\u{642}\u{628}\u{648}\u{644} \u{627}\u{644}\u{637}\u{644}\u{628}';
  static const rejectRequestAction =
      '\u{631}\u{641}\u{636} \u{627}\u{644}\u{637}\u{644}\u{628}';
  static const leaveGroupAction =
      '\u{645}\u{63a}\u{627}\u{62f}\u{631}\u{629} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}';
  static const moveSeatAction =
      '\u{646}\u{642}\u{644} \u{627}\u{644}\u{645}\u{642}\u{639}\u{62f}';
  static const transferOwnershipAction =
      '\u{646}\u{642}\u{644} \u{627}\u{644}\u{645}\u{644}\u{643}\u{64a}\u{629}';
  static const leaveGroupConfirm =
      '\u{633}\u{64a}\u{62a}\u{645} \u{625}\u{641}\u{631}\u{627}\u{63a} \u{645}\u{642}\u{627}\u{639}\u{62f}\u{643} \u{644}\u{644}\u{64a}\u{648}\u{645}. \u{64a}\u{62c}\u{628} \u{646}\u{642}\u{644} \u{627}\u{644}\u{645}\u{644}\u{643}\u{64a}\u{629} \u{642}\u{628}\u{644} \u{645}\u{63a}\u{627}\u{62f}\u{631}\u{629} \u{627}\u{644}\u{645}\u{627}\u{644}\u{643}.';
  static const removeMemberConfirm =
      '\u{633}\u{64a}\u{62a}\u{645} \u{625}\u{632}\u{627}\u{644}\u{629} \u{627}\u{644}\u{639}\u{636}\u{648} \u{648}\u{625}\u{641}\u{631}\u{627}\u{63a} \u{645}\u{642}\u{627}\u{639}\u{62f}\u{647} \u{627}\u{644}\u{645}\u{639}\u{64a}\u{646}\u{629} \u{644}\u{644}\u{64a}\u{648}\u{645}.';
  static const transferOwnershipConfirm =
      '\u{633}\u{62a}\u{646}\u{642}\u{644} \u{645}\u{644}\u{643}\u{64a}\u{629} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629} \u{625}\u{644}\u{649} \u{647}\u{630}\u{627} \u{627}\u{644}\u{639}\u{636}\u{648}.';
  static const approveRequestConfirm =
      '\u{633}\u{64a}\u{646}\u{636}\u{645} \u{635}\u{627}\u{62d}\u{628} \u{627}\u{644}\u{637}\u{644}\u{628} \u{648}\u{64a}\u{62e}\u{62a}\u{627}\u{631} \u{644}\u{647} \u{645}\u{642}\u{639}\u{62f} \u{645}\u{62a}\u{627}\u{62d}.';
  static const rejectRequestConfirm =
      '\u{633}\u{64a}\u{62a}\u{645} \u{631}\u{641}\u{636} \u{637}\u{644}\u{628} \u{627}\u{644}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}.';
  // --- US3 completion screen ---
  static const gracePeriodNotice =
      '\u{627}\u{644}\u{64a}\u{648}\u{645} \u{641}\u{64a} \u{641}\u{62a}\u{631}\u{629} \u{627}\u{644}\u{633}\u{645}\u{627}\u{62d} \u{644}\u{644}\u{625}\u{62a}\u{645}\u{627}\u{645} \u{627}\u{644}\u{645}\u{62a}\u{623}\u{62e}\u{631}.';
  static const confirmUndoAction =
      '\u{62a}\u{623}\u{643}\u{64a}\u{62f} \u{627}\u{644}\u{62a}\u{631}\u{627}\u{62c}\u{639}';
  static const completionDayClosed =
      '\u{627}\u{646}\u{62a}\u{647}\u{649} \u{648}\u{642}\u{62a} \u{625}\u{62a}\u{645}\u{627}\u{645} \u{648}\u{631}\u{62f} \u{627}\u{644}\u{64a}\u{648}\u{645}';
  static String errorMessage(String code) {
    switch (code) {
      case 'network':
        return networkFailure;
      case 'day_closed':
        return completionDayClosed;
      default:
        return dashboardLoadError;
    }
  }

  // --- US5 volunteering ---
  static const volunteerForJuz =
      '\u{623}\u{62a}\u{637}\u{648}\u{639} \u{628}\u{642}\u{631}\u{627}\u{621}\u{62a}\u{647}';
  static const volunteerTaken =
      '\u{645}\u{62a}\u{637}\u{648}\u{639} \u{628}\u{647}';
  static const volunteerConflict =
      'سبق عضو آخر إلى التطوع بهذا الجزء. تم تحديث القائمة.';
  static const volunteeredJuz = 'جزء تطوعت بقراءته';

  static String volunteerFailureMessage(String code) =>
      code == 'juz_already_taken' ? volunteerConflict : networkFailure;

  // --- US7: Daily History strings ---
  static const historyScreenTitle = 'سجل الختمات';
  static const emptyHistoryTitle = 'لا يوجد سجل سابق';
  static const emptyHistoryDesc = 'لم تكتمل أي أيام سابقة في هذه المجموعة بعد.';
  static const historyErrorTitle = 'تعذر تحميل السجل';
  static const historyErrorDesc =
      'حدث خطأ أثناء تحميل السجل. يرجى إعادة المحاولة.';
  static const retryAction = 'إعادة المحاولة';
  static const fullKhatmaBadge = 'ختمة كاملة';
  static const myResultSectionTitle = 'وردك في هذا اليوم';
  static const allMembersDetailTitle = 'تفاصيل الأجزاء والمقاعد';
  static const closeDetailAction = 'إغلاق التفاصيل';
  static const loadMoreHistory = 'عرض أيام سابقة';
  static const unassignedSeat = 'مقعد شاغر';
  static String historyMyJuz(String juzName) => 'وردك: $juzName';
  static String historySeat(String seat) => 'مقعد $seat';

  // --- Dashboard navigation ---
  static const groupMenuTooltip = 'إدارة المجموعة';
  static const groupSettingsAction = 'إعدادات المجموعة';

  // --- S11: Settings strings ---
  static const signOutConfirmTitle = 'تأكيد تسجيل الخروج';
  static const signOutConfirmMessage = 'هل أنت متأكد من رغبتك في تسجيل الخروج؟';
  static const quranTextSizeTitle = 'حجم خط قراءة الأجزاء';
  static const quranPreviewText = 'الجزء الأول';

  // --- 004 portion metadata ---
  static const portionUnitJuz = '\u{627}\u{644}\u{62c}\u{632}\u{621}';
  static const portionUnitHalfJuz =
      '\u{646}\u{635}\u{641} \u{627}\u{644}\u{62c}\u{632}\u{621}';
  static const portionUnitHizb = '\u{627}\u{644}\u{62d}\u{632}\u{628}';
  static const portionUnitQuarter =
      '\u{631}\u{628}\u{639} \u{627}\u{644}\u{62d}\u{632}\u{628}';
  static const portionUnitPage = '\u{627}\u{644}\u{635}\u{641}\u{62d}\u{629}';

  static String portionUnitName(PortionUnit unit) => switch (unit) {
    PortionUnit.juz => portionUnitJuz,
    PortionUnit.halfJuz => portionUnitHalfJuz,
    PortionUnit.hizb => portionUnitHizb,
    PortionUnit.quarter => portionUnitQuarter,
    PortionUnit.page => portionUnitPage,
  };

  /// Formats ordinal unit names using the shared Arabic-Indic numeral formatter.
  static String portionName(PortionUnit unit, int index) =>
      unit == PortionUnit.juz
      ? juzName(index)
      : '${portionUnitName(unit)} ${ArabicNumerals.format(index)}';

  // --- 004 portion units UI ---
  static const portionSelectorTitle = 'الورد اليومي';
  static const startPortionChoice = 'اختر بداية الختمة';
  static const cycleLabel = '\u{627}\u{644}\u{62e}\u{62a}\u{645}\u{629}';
  static const dailyPortionAmount =
      '\u{648}\u{62d}\u{62f}\u{629} \u{648}\u{627}\u{62d}\u{62f}\u{629} \u{644}\u{643}\u{644} \u{639}\u{636}\u{648} \u{64a}\u{648}\u{645}\u{64a}\u{627}';
  static String khatmaDays(int days) => days == 1
      ? 'ختمة يوميًا'
      : days == 2
      ? 'ختمة كل يومين'
      : 'ختمة كل ${ArabicNumerals.format(days)} يومًا';
  static String dailyUnitChip(PortionUnit unit) =>
      '${portionUnitName(unit)} يومي';
  // --- 005 log ---
  static const logScreenTitle = 'السجل';
  static const logCurrentStreak = 'التتابع الحالي';
  static const logBestStreak = 'أطول تتابع';
  static const logMonthSummary = 'أيام مكتملة هذا الشهر';
  static const logDayComplete = 'يوم مكتمل';
  static const logDayPartial = 'يوم يحتوي على ورد فائت';
  static const logVolunteered = 'تطوع';
  static const logEmptyTitle = 'سيظهر سجلك هنا';
  static const logEmptyMessage = 'سجل أول ورد لترى ملخص أيامك وتتابعك.';
  static const logErrorTitle = 'تعذر تحميل السجل';
  static const logErrorMessage =
      'حدث خلل أثناء تحميل السجل. تحقق من الاتصال وأعد المحاولة.';
  static const logDayDetails = 'تفاصيل الورد';
  static const logWeekLabel = 'هذا الأسبوع';
  static const logGroupHistoryAction = 'عرض سجل المجموعة';
  static const membershipLimitMessage = 'يمكنك الانضمام إلى مجموعتين بحد أقصى';
  static const membershipLimitNextStep =
      'اذهب إلى مجموعاتي لمغادرة مجموعة قبل المتابعة.';
  // --- end 005 log ---

  static String portionRange(
    String startSura,
    int startAya,
    String endSura,
    int endAya,
  ) =>
      'من $startSura آية ${ArabicNumerals.format(startAya)} إلى $endSura آية ${ArabicNumerals.format(endAya)}';
  static String cycleProgress(int day, int length, int completed, int total) =>
      'اليوم ${ArabicNumerals.format(day)} من ${ArabicNumerals.format(length)} · أُنجز ${ArabicNumerals.format(completed)} من ${ArabicNumerals.format(total)}';
  static String homeGroupProgress(int day, int completedMembers, int activeMembers) =>
      'اليوم ${ArabicFormatting.isolate(ArabicNumerals.format(day))} من الختمة · قرأ ${ArabicFormatting.isolate(ArabicNumerals.format(completedMembers))} من ${ArabicFormatting.isolate(ArabicNumerals.format(activeMembers))} عضوًا';
  static const restDay = 'لا ورد اليوم';
  static const volunteeredPortion = 'وحدة تطوعت بقراءتها';
  static String restDaySeatLabel(String seat) =>
      '${historySeat(seat)}، $restDay';
  static String pendingPortionChange(PortionUnit unit) =>
      'سيتغير الورد إلى ${portionUnitName(unit)} بداية الختمة القادمة';
  static const confirmPortionChange = 'تأكيد تغيير الورد';
  static const portionChangeAppliesNextCycle =
      'سيبدأ التغيير مع بداية الختمة القادمة.';
  static const portionChangeAppliesImmediately =
      'سيبدأ هذا الورد عند بدء الختمة.';

  // --- 007 profiles ---
  static const portionDetailTitle = 'تفاصيل الورد';
  static const reader = 'القارئ';
  static const unassignedReader = 'غير مسند';
  static const completionTime = 'وقت الإتمام';
  static const readingKind = 'نوع القراءة';
  static const kindSeat = 'ورد المقعد';
  static const kindVolunteer = 'تطوع';
  static const kindOverride = 'تعيين المشرف';
  static const openProfile = 'عرض الملف الشخصي';
  static const volunteerForPortion = 'تطوع لقراءة هذا الورد';
  static const portionVacant = 'هذا المقعد شاغر ومتاح للتطوع';
  static const tagOnTime = 'في الوقت';
  static const tagLate = 'قُرئ متأخرًا';
  static const tagVolunteer = 'تطوع';
  static const tagOverride = 'مُسند';
  static const memberProfileTitle = 'الملف الشخصي';
  static const memberRoleOwner = 'مالك المجموعة';
  static const memberRoleSupervisor = 'مشرف';
  static const memberRoleMember = 'عضو';
  static const memberRoleFormer = 'عضو سابق';
  static const memberSince = 'عضو منذ';
  static const currentStreak = 'سلسلة القراءة الحالية';
  static const completionRate = 'نسبة الإتمام';
  static const portionsRead = 'الأوراد المنجزة';
  static const recentDays = 'الأيام الأخيرة';
  static const noBio = 'لا توجد نبذة شخصية';
  static const profileNotAccessible =
      'لا يمكن عرض هذا الملف الشخصي لأنك لست عضوًا معه في نفس المجموعة';
  static const myProfileTitle = 'ملفي الشخصي';
  static const editProfile = 'تعديل الملف الشخصي';
  static const displayName = 'الاسم الظاهر';
  static const displayNameHint = 'أدخل اسمك الظاهر (٢-٥٠ حرفًا)';
  static const invalidDisplayName = 'يجب أن يكون الاسم بين ٢ و٥٠ حرفًا';
  static const bio = 'النبذة التعريفية';
  static const bioHint = 'نبذة قصيرة عنك (بحد أقصى ١٢٠ حرفًا)';
  static const invalidBio = 'يجب ألا تتجاوز النبذة ١٢٠ حرفًا';
  static const profileUpdated = 'تم تحديث الملف الشخصي بنجاح';
  static const saveChanges = 'حفظ التعديلات';
  static const groupInfoTitle = 'معلومات المجموعة';
  static const groupDescription = 'الوصف';
  static const noDescription = 'لا يوجد وصف للمجموعة';
  static const groupStats = 'إحصائيات المجموعة';
  static const createdDate = 'تاريخ الإنشاء';
  static const completedKhatmas = 'الختمات المكتملة';
  static const groupMembers = 'الأعضاء';
  static const editGroupDetails = 'تعديل بيانات المجموعة';
  static const changeGroupPhoto = 'تغيير صورة المجموعة';
  static const removeGroupPhoto = 'حذف الصورة';
  static const pickFromGallery = 'اختيار من المعرض';
  static const takePhoto = 'التقاط صورة';
  static const uploadingPhoto = 'جاري رفع الصورة...';
  static const photoUploadFailed = 'تعذر رفع الصورة، حاول مرة أخرى';
  static const invalidGroupName = 'يجب أن يكون اسم المجموعة بين ٣ و٦٠ حرفًا';
  static const invalidGroupDescription = 'يجب ألا يتجاوز الوصف ٢٠٠ حرف';
  static const copyInviteCode = 'نسخ رمز الدعوة';
  static const copiedToClipboard = 'تم النسخ إلى الحافظة';
  static String streakDays(int days) =>
      days == 1 ? 'يوم واحد' : '${ArabicNumerals.format(days)} أيام متتالية';
  static String completionPercentage(int rate) =>
      '${ArabicNumerals.format(rate)}٪';
  static String groupMembersRatio(int current, int total) =>
      '${ArabicNumerals.format(current)} عضوًا من ${ArabicNumerals.format(total)}';
  // --- 005 profile ---
  static const profileTitle = 'حسابي';
  static const profileStreakSection = 'التتابع والالتزام';
  static const profileTotalsSection = 'إجمالي القراءة';
  static const profileKhatmasSection = 'الختمات المكتملة';
  static const profileBadgesSection = 'الأوسمة والإنجازات';
  static const profileQuickLinksSection = 'روابط سريعة';

  static String profileMemberSince(String date) => 'عضو منذ $date';
  static String profileStreakDays(int days) =>
      days == 1 ? 'يوم واحد متواصل' : '${ArabicNumerals.format(days)} أيام متواصلة';
  static String bestStreak(int days) =>
      'أفضل تتابع: ${ArabicNumerals.format(days)} ${days == 1 ? "يوم" : "أيام"}';
  static String portionsReadCount(int count) =>
      '${ArabicNumerals.format(count)} جزءًا مقروءًا';
  static String portionsLateCount(int count) =>
      '${ArabicNumerals.format(count)} قُرئت متأخرة';
  static String khatmasCount(int count) =>
      count == 1 ? 'ختمة واحدة' : count == 2 ? 'ختمتان' : '${ArabicNumerals.format(count)} ختمات';
  static const noKhatmasYet = 'لا توجد ختمات مكتملة بعد';

  static const profileLogNavigation = 'السجل اليومي';
  static const profileSettingsNavigation = 'الإعدادات';
  static const profileLoadError = 'تعذر تحميل بيانات الحساب الشخصي';

  // Badges
  static const badgeFirstKhatmaTitle = 'أول ختمة';
  static const badgeFirstKhatmaDesc = 'إتمام أول ختمة كاملة مع مجموعتك';
  static const badgeStreak7Title = 'مداومة ٧ أيام';
  static const badgeStreak7Desc = 'المحافظة على الورد اليومي ٧ أيام متتالية';
  static const badgeStreak30Title = 'مداومة ٣٠ يومًا';
  static const badgeStreak30Desc =
      'ثبات على القراءة ٣٠ يومًا متواصلة بتوفيق الله';
  static const badgeStreak100Title = 'مداومة ١٠٠ يوم';
  static const badgeStreak100Desc = 'اجتهاد مبارك وثبات على تلاوة كتاب الله';
  static const badgePortions100Title = '١٠٠ جزء';
  static const badgePortions100Desc = 'إتمام تلاوة ١٠٠ جزء بتوفيق الله وعونه';

  static String badgeEarned(String date) => 'مكتسب في $date';
  static const badgeLocked = 'لم يُكتسب بعد';
}
