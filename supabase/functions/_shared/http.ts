// Shared HTTP helpers for Kashkool Edge Functions.

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, apikey, x-client-info, content-type, x-webhook-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function fail(message: string, status = 400): Response {
  return json({ ok: false, error: message }, status);
}

export async function readJson(request: Request): Promise<Record<string, unknown>> {
  try {
    const body = await request.json();
    if (body === null || typeof body !== 'object' || Array.isArray(body)) {
      throw new Error('body must be a JSON object');
    }
    return body as Record<string, unknown>;
  } catch (error) {
    throw new Error(`Invalid JSON body: ${(error as Error).message}`);
  }
}

export function text(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${field} is required and must be a non-empty string`);
  }
  return value.trim();
}

export function integer(value: unknown, field: string): number {
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) {
    throw new Error(`${field} must be an integer`);
  }
  return parsed;
}

export function positiveInteger(value: unknown, field: string): number {
  const parsed = integer(value, field);
  if (parsed <= 0) throw new Error(`${field} must be greater than zero`);
  return parsed;
}

/** Provider webhooks must carry the shared secret. No secret = no endpoint. */
export function requireWebhookSecret(request: Request): void {
  const expected = Deno.env.get('WEBHOOK_SECRET');
  if (!expected) {
    throw new Error('WEBHOOK_SECRET is not configured; refusing webhook');
  }
  if (request.headers.get('x-webhook-secret') !== expected) {
    throw new Error('Invalid webhook secret');
  }
}
