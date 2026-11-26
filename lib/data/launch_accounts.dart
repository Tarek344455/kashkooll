import '../core/models/kashkool_models.dart';

class LaunchAccount {
  final String id;
  final UserRole role;
  final String nameAr;
  final String nameEn;
  final String email;
  final String phone;
  final String password;
  final String activationCode;
  final String? studentId;
  final String? linkedStudentId;

  const LaunchAccount({
    required this.id,
    required this.role,
    required this.nameAr,
    required this.nameEn,
    required this.email,
    required this.phone,
    required this.password,
    required this.activationCode,
    this.studentId,
    this.linkedStudentId,
  });
}

const List<LaunchAccount> launchAccounts = [
  LaunchAccount(
    id: 'acc-stu-1',
    role: UserRole.student,
    nameAr: 'أحمد محمد علي',
    nameEn: 'Ahmed Mohamed Ali',
    email: 'ahmed@kashkool.edu.eg',
    phone: '+201012345678',
    password: 'Ksh@2026Stu1',
    activationCode: 'KSH2026A',
    studentId: 'stu-1',
  ),
  LaunchAccount(
    id: 'acc-stu-2',
    role: UserRole.student,
    nameAr: 'سارة خالد حسن',
    nameEn: 'Sara Khaled Hassan',
    email: 'sara@kashkool.edu.eg',
    phone: '+201122334455',
    password: 'Ksh@2026Stu2',
    activationCode: 'KSH2026B',
    studentId: 'stu-2',
  ),
  LaunchAccount(
    id: 'acc-teacher-1',
    role: UserRole.teacher,
    nameAr: 'أ. طارق عزت — معلم الرياضيات والفيزياء',
    nameEn: 'Mr. Tarek Ezzat — Math & Physics',
    email: 'teacher@kashkool.edu.eg',
    phone: '+201000112233',
    password: 'Ksh@2026Teach',
    activationCode: 'KSHTCH26',
  ),
  LaunchAccount(
    id: 'acc-secretary-1',
    role: UserRole.secretary,
    nameAr: 'مكتب السكرتارية — سنتر النخبة',
    nameEn: 'Secretary Desk — Al-Nokhba Center',
    email: 'secretary@kashkool.edu.eg',
    phone: '+201000445566',
    password: 'Ksh@2026Sec',
    activationCode: 'KSHSEC26',
  ),
  LaunchAccount(
    id: 'acc-parent-1',
    role: UserRole.parent,
    nameAr: 'ولي أمر أحمد محمد',
    nameEn: 'Parent of Ahmed Mohamed',
    email: 'parent@kashkool.edu.eg',
    phone: '+201000778899',
    password: 'Ksh@2026Parent',
    activationCode: 'KSHP-2026A',
    linkedStudentId: 'stu-1',
  ),
];

LaunchAccount? findAccountByIdentifier(String identifier) {
  final clean = identifier.trim().toLowerCase();
  if (clean.isEmpty) return null;
  for (final acc in launchAccounts) {
    if (acc.email.toLowerCase() == clean ||
        acc.phone.toLowerCase() == clean ||
        acc.activationCode.toLowerCase() == clean) {
      return acc;
    }
  }
  return null;
}

LaunchAccount? authenticateLaunchAccount(String identifier, String password) {
  final acc = findAccountByIdentifier(identifier);
  if (acc == null) return null;
  if (acc.password == password.trim()) return acc;
  return null;
}

LaunchAccount? authenticateByActivationCode(String code) {
  final clean = code.trim().toUpperCase();
  if (clean.isEmpty) return null;
  for (final acc in launchAccounts) {
    if (acc.activationCode.toUpperCase() == clean) return acc;
  }
  return null;
}
