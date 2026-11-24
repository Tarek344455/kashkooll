// Idempotent CSV/JSON-sheet import into the Postgres tenant tables.
// Rows arrive as JSON in the request body; the deployed function no longer
// depends on local files. Every row is validated and stamped with its tenant.

import { adminClient } from '../_shared/db.ts';
import { corsHeaders, fail, integer, json, readJson, requireWebhookSecret, text } from '../_shared/http.ts';

const TABLES: Record<string, string[]> = {
  students: ['name', 'phone'],
  sessions: ['title', 'startTime'],
  wallet_transactions: ['studentId', 'amountPiasters'],
  attendance: ['studentId', 'sessionId'],
  quizzes: ['title'],
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    requireWebhookSecret(request);
    const body = await readJson(request);
    const table = text(body.table, 'table');
    const required = TABLES[table];
    if (!required) throw new Error(`Unsupported table: ${table}`);
    const tenantId = text(body.tenantId, 'tenantId');
    const idField = typeof body.idField === 'string' ? body.idField : 'id';
    const dryRun = body.dryRun === true;
    const batchSize = body.batchSize === undefined ? 500 : integer(body.batchSize, 'batchSize');
    if (batchSize <= 0 || batchSize > 500) throw new Error('batchSize must be between 1 and 500');
    if (!Array.isArray(body.rows)) throw new Error('rows must be an array');

    let imported = 0;
    let skipped = 0;
    const errors: { row: number; error: string }[] = [];

    for (let i = 0; i < body.rows.length; i += batchSize) {
      const batch = body.rows.slice(i, i + batchSize);
      const prepared: Record<string, unknown>[] = [];
      for (let j = 0; j < batch.length; j++) {
        const rowNumber = i + j + 2; // 1-based + CSV header
        const raw = batch[j];
        if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
          errors.push({ row: rowNumber, error: 'row must be an object' });
          skipped++;
          continue;
        }
        const row = raw as Record<string, unknown>;
        const missing = required.filter((field) =>
          row[field] === undefined || row[field] === null || String(row[field]).trim().length === 0
        );
        if (missing.length) {
          errors.push({ row: rowNumber, error: `missing fields: ${missing.join(', ')}` });
          skipped++;
          continue;
        }
        const id = String(row[idField] ?? row.id ?? '').trim();
        if (!id) {
          errors.push({ row: rowNumber, error: `missing id field: ${idField}` });
          skipped++;
          continue;
        }
        prepared.push({
          ...row,
          id,
          tenant_id: tenantId,
          migration_source: 'google_sheet',
          migrated_at: new Date().toISOString(),
        });
      }

      if (dryRun) {
        imported += prepared.length;
        continue;
      }
      if (prepared.length === 0) continue;
      const { error } = await adminClient()
        .from(table)
        .upsert(prepared, { onConflict: 'id' });
      if (error) throw new Error(`batch at row ${i + 2}: ${error.message}`);
      imported += prepared.length;
    }

    return json({ ok: true, total: body.rows.length, imported, skipped, errors, dryRun });
  } catch (error) {
    const message = (error as Error).message;
    const status = message.includes('not configured') ? 503
      : message.includes('secret') ? 401
      : 400;
    return fail(message, status);
  }
});
