import { createClient, type RealtimeChannel, type Session, type SupabaseClient } from "@supabase/supabase-js";
import type {
  AttendanceEntity,
  GroupEntity,
  LedgerEntryEntity,
  PaymentChannelEntity,
  PaymentSubmissionEntity,
  StudentEntity,
} from "../types/kashkool";
import { LedgerKind } from "../types/kashkool";

let cachedClient: SupabaseClient | null = null;
let cachedConfigKey = "";

export interface SupabasePublicConfig {
  url: string;
  anonKey: string;
}

function isBrowserSafeAnonKey(key: string): boolean {
  const trimmed = key.trim();
  if (!trimmed || /^sb_secret_/i.test(trimmed)) return false;
  if (trimmed.split(".").length === 3) {
    try {
      const payload = JSON.parse(atob(trimmed.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))) as {
        role?: string;
      };
      if (payload.role === "service_role") return false;
    } catch {
      // Ignore non-JWT opaque keys
    }
  }
  return true;
}

function readEnvConfig(): SupabasePublicConfig | null {
  const metaEnv = (import.meta as unknown as { env?: Record<string, string | undefined> }).env;
  const url = metaEnv?.VITE_SUPABASE_URL?.trim() ?? "";
  const anonKey = metaEnv?.VITE_SUPABASE_ANON_KEY?.trim() ?? "";
  if (!url || !anonKey || !/^https?:\/\//i.test(url) || !isBrowserSafeAnonKey(anonKey)) return null;
  return { url, anonKey };
}

export function initSupabaseClient(overrideConfig?: SupabasePublicConfig | null): SupabaseClient | null {
  const cfg = overrideConfig ?? readEnvConfig();
  if (!cfg || !cfg.url || !cfg.anonKey || !/^https?:\/\//i.test(cfg.url) || !isBrowserSafeAnonKey(cfg.anonKey)) {
    return cachedClient;
  }
  const key = `${cfg.url}|${cfg.anonKey}`;
  if (cachedClient && cachedConfigKey === key) {
    return cachedClient;
  }
  cachedConfigKey = key;
  cachedClient = createClient(cfg.url, cfg.anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  });
  return cachedClient;
}

export async function bootstrapSupabaseClient(): Promise<SupabaseClient | null> {
  const local = initSupabaseClient();
  if (local) return local;
  try {
    const resp = await fetch("/api/supabase/config");
    if (!resp.ok) return null;
    const data = (await resp.json()) as {
      configured?: boolean;
      browserReady?: boolean;
      url?: string;
      anonKey?: string;
    };
    if (data.configured && data.browserReady && data.url && data.anonKey) {
      return initSupabaseClient({ url: data.url, anonKey: data.anonKey });
    }
  } catch {
    // Offline or backend unavailable; local center mode continues smoothly
  }
  return null;
}

export function isSupabaseConfigured(): boolean {
  return Boolean(cachedClient ?? readEnvConfig());
}

export function getSupabaseClient(): SupabaseClient | null {
  return initSupabaseClient();
}

export async function getActiveSession(): Promise<Session | null> {
  const client = await bootstrapSupabaseClient();
  if (!client) return null;
  const { data } = await client.auth.getSession();
  return data.session ?? null;
}

export async function requestSupabaseEmailOtp(email: string): Promise<{ sent: boolean; error?: string }> {
  const client = await bootstrapSupabaseClient();
  if (!client) return { sent: false };
  const { error } = await client.auth.signInWithOtp({ email });
  if (error) return { sent: false, error: error.message };
  return { sent: true };
}

export async function verifySupabaseEmailOtp(
  email: string,
  token: string
): Promise<{ ok: boolean; session: Session | null; error?: string }> {
  const client = await bootstrapSupabaseClient();
  if (!client) return { ok: false, session: null };
  const { data, error } = await client.auth.verifyOtp({ email, token, type: "email" });
  if (error) return { ok: false, session: null, error: error.message };
  return { ok: true, session: data.session ?? null };
}

export async function requestSupabasePhoneOtp(phone: string): Promise<{ sent: boolean; error?: string }> {
  const client = await bootstrapSupabaseClient();
  if (!client) return { sent: false };
  const { error } = await client.auth.signInWithOtp({ phone });
  if (error) return { sent: false, error: error.message };
  return { sent: true };
}

export async function verifySupabasePhoneOtp(
  phone: string,
  token: string
): Promise<{ ok: boolean; session: Session | null; error?: string }> {
  const client = await bootstrapSupabaseClient();
  if (!client) return { ok: false, session: null };
  const { data, error } = await client.auth.verifyOtp({ phone, token, type: "sms" });
  if (error) return { ok: false, session: null, error: error.message };
  return { ok: true, session: data.session ?? null };
}

export async function signOutSupabase(): Promise<void> {
  const client = getSupabaseClient();
  if (!client) return;
  await client.auth.signOut().catch(() => undefined);
}

function mapLedgerKindToSupabase(kind: LedgerKind | string): string {
  switch (kind) {
    case LedgerKind.CASH_TOPUP:
      return "topup";
    case LedgerKind.PARTIAL_INSTALLMENT:
      return "payment";
    case LedgerKind.BOOK_RESERVATION:
      return "reservation";
    case LedgerKind.DISCOUNT:
      return "refund";
    case LedgerKind.SETTLEMENT:
      return "settlement";
    case LedgerKind.VOID_ENTRY:
      return "void";
    default:
      return "charge";
  }
}

export interface SyncPendingPayload {
  tenantId: string;
  groups: GroupEntity[];
  students: StudentEntity[];
  attendance: AttendanceEntity[];
  ledger: LedgerEntryEntity[];
  submissions: PaymentSubmissionEntity[];
  channels: PaymentChannelEntity[];
}

export interface SyncResult {
  mode: "supabase" | "local";
  syncedRecords: number;
  error?: string;
}

export async function syncPendingToSupabase(payload: SyncPendingPayload): Promise<SyncResult> {
  const client = await bootstrapSupabaseClient();
  if (!client) {
    return { mode: "local", syncedRecords: 0 };
  }

  const { data: sessionData } = await client.auth.getSession();
  const session = sessionData.session;
  if (!session) {
    return { mode: "local", syncedRecords: 0 };
  }

  let syncedRecords = 0;

  try {
    const pendingGroups = payload.groups.filter((g) => g.syncStatus === "pending");
    if (pendingGroups.length > 0) {
      const { error } = await client.from("groups").upsert(
        pendingGroups.map((g) => ({
          id: g.id,
          tenant_id: payload.tenantId,
          name: g.nameAr,
          subject: g.subjectAr,
          schedule: { ar: g.scheduleAr, en: g.scheduleEn, capacity: g.capacity, enrolled: g.enrolled },
        })),
        { onConflict: "id" }
      );
      if (error) throw new Error(error.message);
      syncedRecords += pendingGroups.length;
    }

    const pendingAttendance = payload.attendance.filter((a) => a.syncStatus === "pending");
    for (const rec of pendingAttendance) {
      const { error } = await client.rpc("record_attendance", {
        p_id: rec.id,
        p_tenant_id: payload.tenantId,
        p_student_id: rec.studentId,
        p_session_id: rec.sessionId,
        p_idempotency_key: rec.id,
        p_scanned_at: new Date(rec.timestampMillis).toISOString(),
      });
      if (error) throw new Error(error.message);
      syncedRecords += 1;
    }

    const pendingLedger = payload.ledger.filter((l) => l.syncStatus === "pending");
    for (const entry of pendingLedger) {
      if (entry.kind === LedgerKind.VOID_ENTRY && entry.voidedEntryId) {
        const { error } = await client.rpc("void_wallet_transaction", {
          p_tenant_id: payload.tenantId,
          p_transaction_id: entry.voidedEntryId,
          p_reason: entry.note,
        });
        if (error) throw new Error(error.message);
      } else {
        const { error } = await client.rpc("record_wallet_transaction", {
          p_id: entry.id,
          p_tenant_id: payload.tenantId,
          p_student_id: entry.studentId,
          p_amount_piasters: entry.amountPiasters,
          p_kind: mapLedgerKindToSupabase(entry.kind),
          p_channel: "cash_desk",
          p_idempotency_key: entry.id,
          p_note: entry.note,
        });
        if (error) throw new Error(error.message);
      }
      syncedRecords += 1;
    }

    const pendingSubmissions = payload.submissions.filter((s) => s.syncStatus === "pending");
    for (const sub of pendingSubmissions) {
      let receiptUrl = sub.receiptUri ?? "";
      if (receiptUrl.startsWith("data:image/")) {
        const res = await fetch(receiptUrl);
        const blob = await res.blob();
        const objectPath = `${payload.tenantId}/${session.user.id}/${sub.id}.jpg`;
        const { error: uploadErr } = await client.storage
          .from("receipts")
          .upload(objectPath, blob, { contentType: "image/jpeg", upsert: true });
        if (!uploadErr) {
          receiptUrl = objectPath;
        }
      }
      const { error } = await client.from("payment_submissions").upsert(
        {
          id: sub.id,
          tenant_id: payload.tenantId,
          student_id: sub.studentId,
          channel_id: sub.channelId,
          amount_piasters: sub.amountPiasters,
          sender_reference: sub.senderReference,
          receipt_url: receiptUrl,
          status: sub.status,
        },
        { onConflict: "id" }
      );
      if (error) throw new Error(error.message);
      syncedRecords += 1;
    }

    return { mode: "supabase", syncedRecords };
  } catch (err) {
    return {
      mode: "supabase",
      syncedRecords,
      error: err instanceof Error ? err.message : "Supabase sync error",
    };
  }
}

export function subscribeToCenterRealtime(
  tenantId: string,
  onRemoteUpdate: () => void
): () => void {
  const client = getSupabaseClient();
  if (!client) return () => undefined;

  const uniqueTopic = `kashkool-center-${tenantId}-${Math.random().toString(36).slice(2, 8)}`;
  const channel: RealtimeChannel = client
    .channel(uniqueTopic)
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "attendance", filter: `tenant_id=eq.${tenantId}` },
      () => onRemoteUpdate()
    )
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "payment_submissions", filter: `tenant_id=eq.${tenantId}` },
      () => onRemoteUpdate()
    )
    .subscribe();

  return () => {
    void client.removeChannel(channel);
  };
}
