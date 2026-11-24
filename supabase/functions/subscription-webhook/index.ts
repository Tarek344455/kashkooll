// Subscription payments: verify amount against the real catalog, then apply
// the whole payment atomically (billing transaction + subscription + tenant).

import { adminClient } from '../_shared/db.ts';
import {
  accountTypeOf,
  billingCycleOf,
  expectedPiasters,
  expiryDate,
  grantModules,
  promoFor,
  validateModules,
} from '../_shared/catalog.ts';
import { corsHeaders, fail, integer, json, readJson, requireWebhookSecret, text } from '../_shared/http.ts';

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    requireWebhookSecret(request);
    const body = await readJson(request);

    const accountId = text(body.accountId, 'accountId');
    const accountType = accountTypeOf(body.accountType);
    if (!accountType) throw new Error('accountType must be teacher or center');
    const cycle = billingCycleOf(body.billingCycle);
    if (!cycle) throw new Error('billingCycle must be monthly or yearly');

    if (!Array.isArray(body.modules) || body.modules.some((id) => typeof id !== 'string')) {
      throw new Error('modules must be an array of strings');
    }
    const modules = body.modules as string[];
    const moduleError = validateModules(modules, accountType);
    if (moduleError) throw new Error(moduleError);

    const promo = promoFor(
      typeof body.promoCode === 'string' ? body.promoCode : undefined,
      accountType,
      modules,
    );
    const charged = integer(body.amountPiasters, 'amountPiasters');
    const expected = expectedPiasters(modules, cycle, promo);
    if (charged !== expected) {
      throw new Error(`amount mismatch: expected ${expected} piasters, received ${charged}`);
    }

    const transactionId = text(body.transactionId, 'transactionId');
    const paymentMethod = text(body.paymentMethod, 'paymentMethod');
    const granted = grantModules(modules, promo);
    const { data, error } = await adminClient().rpc('process_subscription_payment', {
      p_account_id: accountId,
      p_account_type: accountType,
      p_modules: granted,
      p_billing_cycle: cycle,
      p_promo_code: promo?.code ?? null,
      p_payment_method: paymentMethod,
      p_amount_piasters: charged,
      p_transaction_id: transactionId,
      p_expires_at: expiryDate(cycle, promo).toISOString(),
      p_metadata: body.metadata ?? {},
    });
    if (error) throw new Error(error.message);

    return json({ ok: true, ...(data as Record<string, unknown>) });
  } catch (error) {
    const message = (error as Error).message;
    const status = message.includes('not configured') ? 503
      : message.includes('secret') ? 401
      : 400;
    return fail(message, status);
  }
});
