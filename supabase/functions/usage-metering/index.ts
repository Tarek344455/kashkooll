// Usage-based metering. The account is derived from the signed-in profile,
// never from a client-supplied accountId (that would allow billing fraud).

import { adminClient, authenticatedUser } from '../_shared/db.ts';
import { USAGE_PRICE_PIASTERS } from '../_shared/catalog.ts';
import { corsHeaders, fail, json, positiveInteger, readJson, text } from '../_shared/http.ts';

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    const { id: userId, client } = await authenticatedUser(request);
    const body = await readJson(request);
    const meterKey = text(body.meterKey, 'meterKey');
    if (!(meterKey in USAGE_PRICE_PIASTERS)) throw new Error(`Unknown meter: ${meterKey}`);
    const quantity = positiveInteger(body.quantity, 'quantity');

    const { data: profile, error: profileError } = await client
      .from('profiles')
      .select('tenant_id')
      .eq('id', userId)
      .maybeSingle();
    if (profileError) throw new Error(profileError.message);
    const accountId = (profile?.tenant_id as string | null) || userId;

    const { data, error } = await adminClient().rpc('increment_usage', {
      p_account_id: accountId,
      p_meter_key: meterKey,
      p_quantity: quantity,
    });
    if (error) throw new Error(error.message);

    return json({ ok: true, accountId, meterKey, quantity, total: data });
  } catch (error) {
    const message = (error as Error).message;
    return fail(message, message.includes('Authentication') ? 401 : 400);
  }
});
