import { UserRole } from "../types/kashkool";

export interface LaunchAccount {
  id: string;
  role: UserRole;
  nameAr: string;
  nameEn: string;
  email: string;
  phone: string;
  password: string;
  activationCode: string;
  studentId?: string;
  linkedStudentId?: string;
}

export const LAUNCH_ACCOUNTS: LaunchAccount[] = [
  {
    id: "acc-stu-1",
    role: UserRole.STUDENT,
    nameAr: "أحمد محمد علي",
    nameEn: "Ahmed Mohamed Ali",
    email: "ahmed@kashkool.edu.eg",
    phone: "+201012345678",
    password: "Ksh@2026Stu1",
    activationCode: "KSH2026A",
    studentId: "stu-1",
  },
  {
    id: "acc-stu-2",
    role: UserRole.STUDENT,
    nameAr: "سارة خالد حسن",
    nameEn: "Sara Khaled Hassan",
    email: "sara@kashkool.edu.eg",
    phone: "+201122334455",
    password: "Ksh@2026Stu2",
    activationCode: "KSH2026B",
    studentId: "stu-2",
  },
  {
    id: "acc-teacher-1",
    role: UserRole.TEACHER,
    nameAr: "أ. طارق عزت — معلم الرياضيات والفيزياء",
    nameEn: "Mr. Tarek Ezzat — Math & Physics",
    email: "teacher@kashkool.edu.eg",
    phone: "+201000112233",
    password: "Ksh@2026Teach",
    activationCode: "KSHTCH26",
  },
  {
    id: "acc-secretary-1",
    role: UserRole.SECRETARY,
    nameAr: "مكتب السكرتارية — سنتر النخبة",
    nameEn: "Secretary Desk — Al-Nokhba Center",
    email: "secretary@kashkool.edu.eg",
    phone: "+201000445566",
    password: "Ksh@2026Sec",
    activationCode: "KSHSEC26",
  },
  {
    id: "acc-parent-1",
    role: UserRole.PARENT,
    nameAr: "ولي أمر أحمد محمد",
    nameEn: "Parent of Ahmed Mohamed",
    email: "parent@kashkool.edu.eg",
    phone: "+201000778899",
    password: "Ksh@2026Parent",
    activationCode: "KSHP-2026A",
    linkedStudentId: "stu-1",
  },
];

export function findAccountByIdentifier(identifier: string): LaunchAccount | undefined {
  const clean = identifier.trim().toLowerCase();
  if (!clean) return undefined;
  return LAUNCH_ACCOUNTS.find(
    (acc) =>
      acc.email.toLowerCase() === clean ||
      acc.phone.toLowerCase() === clean ||
      acc.activationCode.toLowerCase() === clean
  );
}

export function authenticateLaunchAccount(
  identifier: string,
  secret: string
): LaunchAccount | null {
  const acc = findAccountByIdentifier(identifier);
  if (!acc) return null;
  if (acc.password === secret.trim()) return acc;
  return null;
}

export function authenticateByActivationCode(code: string): LaunchAccount | null {
  const clean = code.trim().toUpperCase();
  if (!clean) return null;
  return LAUNCH_ACCOUNTS.find((acc) => acc.activationCode.toUpperCase() === clean) ?? null;
}
