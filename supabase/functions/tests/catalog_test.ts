import { assertEquals } from 'jsr:@std/assert';
import {
  expectedPiasters,
  expiryDate,
  grantModules,
  promoFor,
  usagePiasters,
  validateModules,
} from '../_shared/catalog.ts';

Deno.test('rejects modules from the wrong account type', () => {
  assertEquals(validateModules(['teacherCore'], 'center'), 'module teacherCore is not available for center accounts');
  assertEquals(validateModules(['centerCore', 'centerAttendancePro'], 'center'), null);
});

Deno.test('real monthly and yearly catalog prices', () => {
  assertEquals(expectedPiasters(['centerCore'], 'monthly', null), 0);
  assertEquals(expectedPiasters(['centerAttendancePro'], 'monthly', null), 20000);
  assertEquals(expectedPiasters(['centerAttendancePro'], 'yearly', null), 200000);
});

Deno.test('BUNDLE2 halves the second module, no fake math', () => {
  const promo = promoFor('BUNDLE2', 'center', ['centerSettlementEngine', 'centerFamilyWallet']);
  // 30000 + 15000 - round(15000/2) = 37500 piasters (375 EGP).
  assertEquals(expectedPiasters(['centerSettlementEngine', 'centerFamilyWallet'], 'monthly', promo), 37500);
});

Deno.test('TEACHERFREE grants the teacher core module with settlement', () => {
  const promo = promoFor('TEACHERFREE', 'center', ['centerSettlementEngine']);
  assertEquals(grantModules(['centerSettlementEngine'], promo), ['centerSettlementEngine', 'teacherCore']);
  assertEquals(promoFor('TEACHERFREE', 'teacher', ['teacherCore']), null);
});

Deno.test('TRIAL3 extends expiry by three months', () => {
  const promo = promoFor('TRIAL3', 'center', ['centerCore']);
  const base = expiryDate('monthly', null).getTime();
  const trial = expiryDate('monthly', promo).getTime();
  assertEquals(trial > base + 80 * 24 * 3600 * 1000, true);
});

Deno.test('usage meters use real per-unit piasters', () => {
  assertEquals(usagePiasters('sms', 1000), 2500);
  assertEquals(usagePiasters('unknown', 10), null);
});
