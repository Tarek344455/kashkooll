// Context-aware study assistant. A semantic cache avoids repeat inference;
// answers come from the configured Kashkool Savior gateway only. If that
// gateway is not configured the function fails loudly — it never invents a
// canned "Socratic" answer.

import { adminClient, authenticatedUser } from '../_shared/db.ts';
import { corsHeaders, fail, json, readJson, text } from '../_shared/http.ts';

function cacheKey(tenantId: string, lessonId: string, query: string): string {
  const bytes = new TextEncoder().encode(`${tenantId}:${lessonId}:${query}`);
  let hash = 2166136261;
  for (const byte of bytes) hash = Math.imul(hash ^ byte, 16777619);
  return `${tenantId}-${(hash >>> 0).toString(16)}`;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    const { id: userId, client } = await authenticatedUser(request);
    const body = await readJson(request);
    const query = text(body.query, 'query');
    const lessonId = typeof body.lessonId === 'string' ? body.lessonId : '';

    const { data: profile, error: profileError } = await client
      .from('profiles')
      .select('tenant_id')
      .eq('id', userId)
      .maybeSingle();
    if (profileError) throw new Error(profileError.message);
    const tenantId = profile?.tenant_id as string | null;
    if (!tenantId) throw new Error('Account is not enrolled in a centre');
    const key = cacheKey(tenantId, lessonId, query);

    const db = adminClient();
    const { data: cached } = await db
      .from('knowledge_cache')
      .select('answer,expires_at')
      .eq('id', key)
      .maybeSingle();
    if (cached && (!cached.expires_at || new Date(cached.expires_at as string) > new Date())) {
      return json({ ok: true, answer: cached.answer, cached: true });
    }

    const gateway = Deno.env.get('SAVIOR_GATEWAY_URL');
    const gatewayKey = Deno.env.get('SAVIOR_GATEWAY_KEY');
    if (!gateway) throw new Error('SAVIOR_GATEWAY_URL is not configured');

    const prompt = JSON.stringify({ ctx: lessonId, q: query, lvl: body.level ?? 'student' });
    const response = await fetch(`${gateway.replace(/\/$/, '')}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(gatewayKey ? { Authorization: `Bearer ${gatewayKey}` } : {}),
      },
      body: JSON.stringify({
        model: 'kashkool-savior',
        messages: [
          {
            role: 'system',
            content:
              'أنت المساعد الدراسي في كشكول. اشرح خطوة بخطوة بأسلوب سقراطي، ' +
              'ولا تعطي الإجابة النهائية مباشرة. استخدم العربية المصرية البسيطة.',
          },
          { role: 'user', content: prompt },
        ],
      }),
      signal: AbortSignal.timeout(60_000),
    });
    if (!response.ok) throw new Error(`Inference gateway returned HTTP ${response.status}`);
    const payload = await response.json();
    const answer = payload?.choices?.[0]?.message?.content;
    if (typeof answer !== 'string' || answer.length === 0) {
      throw new Error('Inference gateway returned an empty answer');
    }

    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString();
    await db.from('knowledge_cache').upsert({
      id: key,
      tenant_id: tenantId,
      answer: { text: answer },
      created_at: new Date().toISOString(),
      expires_at: expiresAt,
    }, { onConflict: 'id' });

    return json({ ok: true, answer: { text: answer }, cached: false });
  } catch (error) {
    const message = (error as Error).message;
    const status = message.includes('not configured') ? 503
      : message.includes('Authentication') ? 401
      : 400;
    return fail(message, status);
  }
});
