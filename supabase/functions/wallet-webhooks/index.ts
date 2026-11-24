// Payment-provider webhooks -> immutable wallet ledger.
// Provider is explicit (?provider=fawry|vodafone_cash|insta_pay). Every payload
// must name the student, the tenant and an integer piasters amount; nothing is
// inferred, because a wrong student id would corrupt the money ledger.

import { adminClient } from '../_shared/db.ts';
import {
  corsHeaders,
  fail,
  json,
  positiveInteger,
  readJson,
  requireWebhookSecret,
  text,
} from '../_shared/http.ts';

const CHANNELS: Record<string, { tenantField: string; referenceField: string }> = {
  fawry: { tenantField: 'tenantId', referenceField: 'merchantRef' },
  vodafone_cash: { tenantField: 'tenantId', referenceField: 'reference' },
  insta_pay: { tenantField: 'tenantId', referenceField: 'transactionId' },
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    requireWebhookSecret(request);
    const provider = new URL(request.url).searchParams.get('provider') ?? '';
    const fields = CHANNELS[provider];
    if (!fields) throw new Error('Unknown or missing provider');

    const body = await readJson(request);
    const status = text(body.status, 'status');
    if (status.toUpperCase() !== 'SUCCESS') throw new Error('Payment was not successful');

    const tenantId = text(body[fields.tenantField], fields.tenantField);
    const studentId = text(body.studentId, 'studentId');
    const reference = text(body[fields.referenceField], fields.referenceField);
    const amountPiasters = positiveInteger(body.amountPiasters, 'amountPiasters');

    const { data, error } = await adminClient().rpc('record_wallet_transaction', {
      p_id: `${provider}:${reference}`,
      p_tenant_id: tenantId,
      p_student_id: studentId,
      p_amount_piasters: amountPiasters,
      p_kind: 'topup',
      p_channel: provider,
      p_reference_id: reference,
      p_idempotency_key: `${provider}:${reference}`,
      p_note: `Verified ${provider} webhook`,
    });
    if (error) throw new Error(error.message);

    return json({ ok: true, transaction: data });
  } catch (error) {
    const message = (error as Error).message;
    const status = message.includes('not configured') ? 503
      : message.includes('secret') ? 401
      : 400;
    return fail(message, status);
  }
});
