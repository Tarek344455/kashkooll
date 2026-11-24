// Mirrors the verified catalog in packages/kashkool_core/lib/models/pricing_model.dart.
// Prices are integer piasters (1 EGP = 100 piasters). YEARLY prices already
// include the "10 months for 12" discount.

export type AccountType = 'teacher' | 'center';
export type BillingCycle = 'monthly' | 'yearly';
export type PromoType =
  | 'freeMonths'
  | 'percentOff'
  | 'bundleDiscount'
  | 'freeModule'
  | 'referralCredit';

export interface ModulePrice {
  id: string;
  accountType: AccountType;
  monthly: number;
  yearly: number;
}

export interface Promo {
  code: string;
  type: PromoType;
  value: number | string;
  maxUses?: number;
  maxUsesPerAccount?: number;
  accountTypes: AccountType[];
  applicableModules?: string[];
}

export const MODULES: readonly ModulePrice[] = [
  { id: 'teacherCore', accountType: 'teacher', monthly: 0, yearly: 0 },
  { id: 'teacherSettlementAuto', accountType: 'teacher', monthly: 5000, yearly: 50000 },
  { id: 'teacherWalletPayout', accountType: 'teacher', monthly: 3000, yearly: 30000 },
  { id: 'teacherContentDrm', accountType: 'teacher', monthly: 4000, yearly: 40000 },
  { id: 'teacherStudentInsights', accountType: 'teacher', monthly: 3000, yearly: 30000 },
  { id: 'teacherMultiCenter', accountType: 'teacher', monthly: 2000, yearly: 20000 },
  { id: 'teacherWhiteLabelParentApp', accountType: 'teacher', monthly: 10000, yearly: 100000 },
  { id: 'centerCore', accountType: 'center', monthly: 0, yearly: 0 },
  { id: 'centerAttendancePro', accountType: 'center', monthly: 20000, yearly: 200000 },
  { id: 'centerSettlementEngine', accountType: 'center', monthly: 30000, yearly: 300000 },
  { id: 'centerFamilyWallet', accountType: 'center', monthly: 15000, yearly: 150000 },
  { id: 'centerTeacherPortal', accountType: 'center', monthly: 10000, yearly: 100000 },
  { id: 'centerStudentEngagement', accountType: 'center', monthly: 12000, yearly: 120000 },
  { id: 'centerMultiBranch', accountType: 'center', monthly: 20000, yearly: 200000 },
  { id: 'centerGodModeRadar', accountType: 'center', monthly: 50000, yearly: 500000 },
  { id: 'centerCustomIntegrations', accountType: 'center', monthly: 30000, yearly: 300000 },
  { id: 'centerWhiteLabelEverything', accountType: 'center', monthly: 80000, yearly: 800000 },
] as const;

export const PROMOS: readonly Promo[] = [
  {
    code: 'TRIAL3',
    type: 'freeMonths',
    value: 3,
    maxUses: 50,
    maxUsesPerAccount: 1,
    accountTypes: ['teacher', 'center'],
  },
  {
    code: 'BUNDLE2',
    type: 'bundleDiscount',
    value: 50,
    maxUsesPerAccount: 1,
    accountTypes: ['teacher', 'center'],
  },
  {
    code: 'YEARLY',
    type: 'percentOff',
    value: 17,
    accountTypes: ['teacher', 'center'],
  },
  {
    code: 'TEACHERFREE',
    type: 'freeModule',
    value: 'teacherCore',
    accountTypes: ['center'],
    applicableModules: ['centerSettlementEngine'],
  },
  {
    code: 'REFERRAL',
    type: 'referralCredit',
    value: 1,
    accountTypes: ['teacher', 'center'],
  },
] as const;

export const USAGE_PRICE_PIASTERS: Record<string, number> = {
  sms: 2.5,
  whatsapp: 2.5,
  ai_remedial: 10,
  storage: 500,
  api_calls: 0.15,
};

export function accountTypeOf(value: unknown): AccountType | null {
  return value === 'teacher' || value === 'center' ? value : null;
}

export function billingCycleOf(value: unknown): BillingCycle | null {
  return value === 'monthly' || value === 'yearly' ? value : null;
}

export function findModule(id: string): ModulePrice | undefined {
  return MODULES.find((module) => module.id === id);
}

/** Rejects unknown ids and modules that belong to another account type. */
export function validateModules(
  modules: string[],
  accountType: AccountType,
): string | null {
  if (modules.length === 0) return 'modules must not be empty';
  for (const id of modules) {
    const module = findModule(id);
    if (!module) return `unknown module: ${id}`;
    if (module.accountType !== accountType) {
      return `module ${id} is not available for ${accountType} accounts`;
    }
  }
  if (new Set(modules).size !== modules.length) return 'modules contains duplicates';
  return null;
}

export function promoFor(
  code: string | undefined,
  accountType: AccountType,
  modules: string[],
): Promo | null {
  if (!code) return null;
  const promo = PROMOS.find((entry) => entry.code === code);
  if (!promo || !promo.accountTypes.includes(accountType)) return null;
  if (
    promo.applicableModules &&
    !promo.applicableModules.some((id) => modules.includes(id))
  ) {
    return null;
  }
  return promo;
}

/** Verified amount in piasters, including real bundle pricing (no mock math). */
export function expectedPiasters(
  modules: string[],
  cycle: BillingCycle,
  promo: Promo | null,
): number {
  const prices = modules
    .map((id) => findModule(id))
    .filter((module): module is ModulePrice => module !== undefined)
    .map((module) => (cycle === 'monthly' ? module.monthly : module.yearly))
    .sort((a, b) => b - a);
  let total = prices.reduce((sum, price) => sum + price, 0);

  if (promo?.type === 'bundleDiscount' && prices.length >= 2) {
    const percent = typeof promo.value === 'number' ? promo.value : 0;
    total -= Math.round((prices[1] * percent) / 100);
  }
  // YEARLY prices already encode the 17% annual discount; other promos here
  // grant time or modules, not a further markup/markdown on the charged amount.
  return Math.max(0, total);
}

export function expiryDate(cycle: BillingCycle, promo: Promo | null): Date {
  const base = new Date();
  if (cycle === 'yearly') base.setUTCDate(base.getUTCDate() + 365);
  else base.setUTCMonth(base.getUTCMonth() + 1);
  if (
    promo &&
    (promo.type === 'freeMonths' || promo.type === 'referralCredit') &&
    typeof promo.value === 'number'
  ) {
    base.setUTCMonth(base.getUTCMonth() + promo.value);
  }
  return base;
}

export function grantModules(modules: string[], promo: Promo | null): string[] {
  const granted = [...modules];
  if (promo?.type === 'freeModule' && typeof promo.value === 'string' && !granted.includes(promo.value)) {
    granted.push(promo.value);
  }
  return granted;
}

export function usagePiasters(meterKey: string, quantity: number): number | null {
  const price = USAGE_PRICE_PIASTERS[meterKey];
  if (price === undefined) return null;
  return Math.round(price * quantity);
}
