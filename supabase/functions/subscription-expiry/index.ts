// Daily subscription expiry sweep (03:00 UTC via pg_cron).
// The SQL RPC deactivates modules and writes the audit entries in one transaction.

import { adminClient } from '../_shared/db.ts';
import { corsHeaders, fail, json } from '../_shared/http.ts';

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    const { data, error } = await adminClient().rpc('expire_subscriptions');
    if (error) throw new Error(error.message);
    return json({ ok: true, ...(data as Record<string, unknown>) });
  } catch (error) {
    return fail((error as Error).message, 500);
  }
});
