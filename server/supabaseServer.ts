import { createClient, type SupabaseClient } from "@supabase/supabase-js";

export interface ServerSupabaseConfig {
  url: string;
  key: string;
  isPublicAnonKey: boolean;
}

export function isPublicSupabaseAnonKey(key: string): boolean {
  const trimmed = key.trim();
  if (!trimmed) return false;
  if (/^sb_secret_/i.test(trimmed)) return false;
  if (trimmed.split(".").length === 3) {
    try {
      const payload = JSON.parse(Buffer.from(trimmed.split(".")[1], "base64url").toString("utf8")) as {
        role?: string;
      };
      if (payload.role === "service_role") return false;
    } catch {
      // Non-JSON JWT segment; treat as opaque
    }
  }
  return true;
}

export function readServerSupabaseConfig(): ServerSupabaseConfig | null {
  const url = (process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL ?? "").trim();
  const key = (process.env.SUPABASE_ANON_KEY ?? process.env.VITE_SUPABASE_ANON_KEY ?? "").trim();
  if (!url || !key || !/^https?:\/\//i.test(url)) return null;
  return {
    url,
    key,
    isPublicAnonKey: isPublicSupabaseAnonKey(key),
  };
}

export function createServerSupabaseClient(): SupabaseClient | null {
  const cfg = readServerSupabaseConfig();
  if (!cfg) return null;
  return createClient(cfg.url, cfg.key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
