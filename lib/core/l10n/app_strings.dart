import '../models/kashkool_models.dart';

class AppStrings {
  static String tr(AppLanguage lang, String key) {
    final map = lang == AppLanguage.ar ? _ar : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static String formatPiasters(int piasters, AppLanguage lang) {
    final egp = (piasters / 100).toStringAsFixed(0);
    return lang == AppLanguage.ar ? '$egp ج.م' : '$egp EGP';
  }

  static const Map<String, String> _en = {
    'app_title': 'Kashkool',
    'welcome': 'Welcome to Kashkool',
    'subtitle_cosmic': 'Smart Egyptian Educational Center & Study Platform',
    'zero_cost_badge': 'Al-Nokhba Educational Platform',
    'email_label': 'Email Address',
    'password_label': 'Password',
    'qr_code_label': 'Center Activation Code',
    'sign_in': 'Sign In',
    'activate_qr': 'Sign In with Code',
    'sign_out': 'Sign Out',
    'role_student': 'Student',
    'role_secretary': 'Secretary',
    'role_teacher': 'Teacher',
    'role_parent': 'Parent',
    'nav_home': 'Home',
    'nav_desk': 'Desk',
    'nav_analytics': 'Analytics',
    'nav_teacher': 'Center',
    'nav_courses': 'Lessons',
    'nav_wallet': 'Wallet',
    'nav_assistant': 'Helper',
    'nav_parent': 'Parent',
    'wallet_balance': 'Wallet Balance',
    'due_balance': 'Balance Due',
    'streak_days': 'Streak',
    'student_mastery': 'Subject Mastery',
    'attendance': 'Attendance',
    'treasury_today': "Today's Collections",
    'quick_actions': 'Quick Access',
    'dynamic_qr_title': 'Session Check-In Code',
    'rotates_in': 'Refreshes in',
    'courses_tab': 'Lectures',
    'quiz_tab': 'Practice Quiz',
    'assistant_title': 'Study Helper',
    'assistant_subtitle': 'Calm step-by-step guidance tailored to your curriculum',
    'assistant_hint': 'Ask any math or physics question...',
    'send': 'Send',
    'immutable_ledger': 'Financial Ledger',
    'void_entry': 'Void Entry',
    'no_pending_receipts': 'No pending receipts right now.',
    'parent_dignity_alert':
        'Balance is running low — top up early so your child enters smoothly.',
    'parent_cheer_cta': 'Copy Encouragement Message',
    'parent_cheer_copied': 'Encouragement message copied!',
    'err_invalid_credentials': 'Invalid email, password, or activation code.',
    'flag_secure_active': 'Protected Educational Workspace',
  };

  static const Map<String, String> _ar = {
    'app_title': 'كشكول',
    'welcome': 'أهلاً بك في كشكول',
    'subtitle_cosmic': 'منصة إدارة السناتر التعليمية والمذاكرة الذكية',
    'zero_cost_badge': 'منصة النخبة التعليمية',
    'email_label': 'البريد الإلكتروني',
    'password_label': 'كلمة المرور',
    'qr_code_label': 'كود تفعيل السنتر',
    'sign_in': 'تسجيل الدخول',
    'activate_qr': 'دخول بالكود',
    'sign_out': 'تسجيل الخروج',
    'role_student': 'طالب',
    'role_secretary': 'سكرتارية',
    'role_teacher': 'معلم',
    'role_parent': 'ولي أمر',
    'nav_home': 'الرئيسية',
    'nav_desk': 'الاستقبال',
    'nav_analytics': 'التحليلات',
    'nav_teacher': 'إدارة السنتر',
    'nav_courses': 'الدروس',
    'nav_wallet': 'الحسابات',
    'nav_assistant': 'المساعد',
    'nav_parent': 'ولي الأمر',
    'wallet_balance': 'الرصيد المتاح',
    'due_balance': 'متبقي عليه',
    'streak_days': 'سلسلة الالتزام',
    'student_mastery': 'إتقان المنهج',
    'attendance': 'الحضور',
    'treasury_today': 'تحصيل اليوم',
    'quick_actions': 'اختصارات سريعة',
    'dynamic_qr_title': 'كود حضور الحصة',
    'rotates_in': 'يتجدد خلال',
    'courses_tab': 'المحاضرات',
    'quiz_tab': 'اختبار سريع',
    'assistant_title': 'المساعد الدراسي',
    'assistant_subtitle': 'شرح هادئ خطوة بخطوة على نفس منهجك',
    'assistant_hint': 'اكتب أي مسألة أو فكرة محتاج تفهمها...',
    'send': 'إرسال',
    'immutable_ledger': 'سجل المعاملات المالية',
    'void_entry': 'إلغاء قيد',
    'no_pending_receipts': 'مفيش إيصالات جديدة مستنية المراجعة دلوقتي.',
    'parent_dignity_alert':
        'الرصيد قرب يخلص — اشحن بدري عشان ابنك يدخل القاعة بارتياح ومن غير تأخير.',
    'parent_cheer_cta': 'نسخ رسالة تشجيع لابنك',
    'parent_cheer_copied': 'تم نسخ رسالة التشجيع — ابعتهاله وفرحه!',
    'err_invalid_credentials':
        'البريد الإلكتروني أو كلمة المرور أو كود التفعيل غير صحيح.',
    'flag_secure_active': 'مساحة تعليمية محمية',
  };
}
