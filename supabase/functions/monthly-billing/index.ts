// Monthly usage billing (1st of month 02:00 UTC via pg_cron).
// Aggregates real usage_events into invoices. One invoice per account/period;
// reruns update the same invoice instead of duplicating charges.

import { adminClient } from '../_shared/db.ts';
import { usagePiasters } from '../_shared/catalog.ts';
import { corsHeaders, fail, json } from '../_shared/http.ts';

function monthBounds(now: Date): { start: Date; end: Date } {
  return {
    start: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1)),
    end: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)),
  };
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    const db = adminClient();
    const { start, end } = monthBounds(new Date());
    const periodStart = start.toISOString();

    const { data: events, error } = await db
      .from('usage_events')
      .select('account_id,meter_key,quantity')
      .gte('created_at', periodStart)
      .lt('created_at', end.toISOString());
    if (error) throw new Error(error.message);

    const totals = new Map<string, { piasters: number; items: Record<string, number> }>();
    for (const event of events ?? []) {
      const accountId = event.account_id as string;
      const meterKey = event.meter_key as string;
      const price = usagePiasters(meterKey, Number(event.quantity) || 0);
      if (price === null) continue;
      const entry = totals.get(accountId) ?? { piasters: 0, items: {} };
      entry.piasters += price;
      entry.items[meterKey] = (entry.items[meterKey] ?? 0) + (Number(event.quantity) || 0);
      totals.set(accountId, entry);
    }

    let invoices = 0;
    for (const [accountId, entry] of totals) {
      const { error: upsertError } = await db.from('invoices').upsert({
        account_id: accountId,
        type: 'usage',
        period_start: periodStart,
        period_end: end.toISOString(),
        items: entry.items,
        total_piasters: entry.piasters,
        status: 'pending',
      }, { onConflict: 'account_id,type,period_start' });
      if (upsertError) throw new Error(upsertError.message);
      invoices++;
    }

    return json({ ok: true, periodStart, periodEnd: end.toISOString(), invoices });
  } catch (error) {
    return fail((error as Error).message, 500);
  }
});
