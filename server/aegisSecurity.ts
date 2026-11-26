import crypto from "node:crypto";

const SERVER_HMAC_SECRET =
  process.env.KASHKOOL_HMAC_SECRET?.trim() || crypto.randomBytes(32).toString("hex");
const LOCAL_QR_SESSION_SECRET =
  process.env.KASHKOOL_QR_SECRET?.trim() || "kashkool-local-session-hmac-secret-2026";

export interface AuditLogEntry {
  id: string;
  tenantId: string;
  actorId: string;
  actorRole: string;
  action: string;
  targetTable: string;
  targetId: string;
  detail: string;
  beforeState: unknown;
  afterState: unknown;
  createdAtMillis: number;
}

export interface DeviceBindingRecord {
  id: string;
  tenantId: string;
  actorId: string;
  deviceFingerprint: string;
  deviceLabel: string;
  isRevoked: boolean;
  suspiciousVelocity: boolean;
  lastSeenAtMillis: number;
  createdAtMillis: number;
}

export class AegisSecurityService {
  private readonly nonces = new Map<string, number>();
  private readonly auditLogs: AuditLogEntry[] = [];
  private readonly devices = new Map<string, DeviceBindingRecord>();
  private readonly devicesByActor = new Map<string, Map<string, DeviceBindingRecord>>();
  private readonly maxAuditLogs = 2000;
  private seq = 0;

  constructor() {
    this.recordAudit({
      tenantId: "demo-centre",
      actorId: "system",
      actorRole: "system",
      action: "AEGIS_INIT",
      targetTable: "security_audit_logs",
      targetId: "boot",
      detail: "Kashkool Aegis Shield active: HMAC anti-replay, device binding & immutable ledger",
    });
  }

  getHmacSecret(): string {
    return SERVER_HMAC_SECRET;
  }

  signPayload(payload: string): string {
    return crypto.createHmac("sha256", SERVER_HMAC_SECRET).update(payload).digest("hex");
  }

  verifySignedPayload(params: {
    payload: string;
    nonce: string;
    timestampMs: number;
    signatureHex: string;
    maxSkewMs?: number;
  }): { ok: boolean; reason?: string } {
    const skew = params.maxSkewMs ?? 120_000;
    const now = Date.now();
    if (!Number.isFinite(params.timestampMs) || Math.abs(now - params.timestampMs) > skew) {
      return { ok: false, reason: "Timestamp outside allowed window" };
    }
    if (!params.nonce || params.nonce.length < 8) {
      return { ok: false, reason: "Invalid monotonic nonce" };
    }
    if (this.nonces.has(params.nonce)) {
      return { ok: false, reason: "Replay attack blocked: nonce already consumed" };
    }
    const expected = this.signPayload(`${params.payload}|${params.nonce}|${params.timestampMs}`);
    const a = Buffer.from(expected, "hex");
    const b = Buffer.from(params.signatureHex.trim(), "hex");
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
      return { ok: false, reason: "Invalid HMAC signature" };
    }
    this.consumeNonce(params.nonce, now + skew);
    return { ok: true };
  }

  consumeNonce(nonce: string, expiresAtMs: number): boolean {
    this.pruneNonces();
    if (this.nonces.has(nonce)) return false;
    this.nonces.set(nonce, expiresAtMs);
    return true;
  }

  private pruneNonces(): void {
    if (this.nonces.size < 5000) return;
    const now = Date.now();
    for (const [key, exp] of this.nonces.entries()) {
      if (exp < now) this.nonces.delete(key);
    }
  }

  verifyDynamicQrAntiReplay(params: {
    rawPayload: string;
    nonce?: string;
    sessionId?: string;
    windowSeconds?: number;
  }): { status: "VALID" | "EXPIRED" | "INVALID" | "REPLAYED"; studentId?: string; sessionId?: string } {
    const trimmed = params.rawPayload.trim();
    const expectedSession = params.sessionId ?? "sess-nokhba-today";
    const windowSec = params.windowSeconds ?? 30;
    const nowSec = Math.floor(Date.now() / 1000);
    const currentBucket = Math.floor(nowSec / windowSec);

    if (trimmed.startsWith("KSHS|")) {
      const parts = trimmed.split("|");
      if (parts.length !== 5) return { status: "INVALID" };
      const [, studentId, sess, bucketStr, sig] = parts;
      const bucket = Number(bucketStr);
      if (!studentId || sess !== expectedSession || !Number.isInteger(bucket)) {
        return { status: "INVALID" };
      }
      const expectedSig = crypto
        .createHmac("sha256", LOCAL_QR_SESSION_SECRET)
        .update(`student:${studentId}:${sess}:${bucket}`)
        .digest("hex")
        .slice(0, 16);
      if (expectedSig.toLowerCase() !== sig.toLowerCase()) {
        return { status: "INVALID" };
      }
      if (bucket !== currentBucket && bucket !== currentBucket - 1) {
        return { status: "EXPIRED", studentId, sessionId: sess };
      }
      const replayKey = params.nonce ? `qr:${params.nonce}` : `qr-tok:${trimmed}`;
      if (!this.consumeNonce(replayKey, Date.now() + 90_000)) {
        this.recordAudit({
          tenantId: "demo-centre",
          actorId: studentId,
          actorRole: "student",
          action: "QR_REPLAY_BLOCKED",
          targetTable: "qr_nonces",
          targetId: replayKey.slice(0, 32),
          detail: "Blocked duplicate dynamic QR scan replay attempt",
        });
        return { status: "REPLAYED", studentId, sessionId: sess };
      }
      return { status: "VALID", studentId, sessionId: sess };
    }

    if (trimmed.startsWith("KSH|")) {
      const parts = trimmed.split("|");
      if (parts.length !== 4) return { status: "INVALID" };
      const [, sess, bucketStr, sig] = parts;
      const bucket = Number(bucketStr);
      if (sess !== expectedSession || !Number.isInteger(bucket)) return { status: "INVALID" };
      const expectedSig = crypto
        .createHmac("sha256", LOCAL_QR_SESSION_SECRET)
        .update(`${sess}:${bucket}`)
        .digest("hex")
        .slice(0, 16);
      if (expectedSig.toLowerCase() !== sig.toLowerCase()) return { status: "INVALID" };
      if (bucket !== currentBucket && bucket !== currentBucket - 1) {
        return { status: "EXPIRED", sessionId: sess };
      }
      if (params.nonce && !this.consumeNonce(`gate:${params.nonce}`, Date.now() + 90_000)) {
        return { status: "REPLAYED", sessionId: sess };
      }
      return { status: "VALID", sessionId: sess };
    }

    return { status: "INVALID" };
  }

  bindDevice(params: {
    tenantId: string;
    actorId: string;
    deviceFingerprint: string;
    deviceLabel: string;
  }): { record: DeviceBindingRecord; velocityAlert: boolean } {
    const actorKey = `${params.tenantId}:${params.actorId}`;
    let actorDevices = this.devicesByActor.get(actorKey);
    if (!actorDevices) {
      actorDevices = new Map<string, DeviceBindingRecord>();
      this.devicesByActor.set(actorKey, actorDevices);
    }

    const key = `${actorKey}:${params.deviceFingerprint}`;
    const existing = this.devices.get(key);
    const now = Date.now();

    let velocityAlert = false;
    for (const d of actorDevices.values()) {
      if (
        !d.isRevoked &&
        d.deviceFingerprint !== params.deviceFingerprint &&
        now - d.lastSeenAtMillis < 300_000
      ) {
        velocityAlert = true;
        break;
      }
    }

    if (existing) {
      const updated: DeviceBindingRecord = {
        ...existing,
        lastSeenAtMillis: now,
        suspiciousVelocity: existing.suspiciousVelocity || velocityAlert,
      };
      this.devices.set(key, updated);
      actorDevices.set(params.deviceFingerprint, updated);
      return { record: updated, velocityAlert };
    }

    const record: DeviceBindingRecord = {
      id: `dev-${++this.seq}-${(now & 0xffff).toString(16)}`,
      tenantId: params.tenantId,
      actorId: params.actorId,
      deviceFingerprint: params.deviceFingerprint,
      deviceLabel: params.deviceLabel || "Web Client",
      isRevoked: false,
      suspiciousVelocity: velocityAlert,
      lastSeenAtMillis: now,
      createdAtMillis: now,
    };
    this.devices.set(key, record);
    actorDevices.set(params.deviceFingerprint, record);

    this.recordAudit({
      tenantId: params.tenantId,
      actorId: params.actorId,
      actorRole: "student",
      action: velocityAlert ? "DEVICE_VELOCITY_ALERT" : "DEVICE_BOUND",
      targetTable: "device_bindings",
      targetId: record.id,
      detail: velocityAlert
        ? `Multi-device login detected for ${params.actorId} (${params.deviceLabel})`
        : `Bound hardware device ${params.deviceLabel}`,
    });

    return { record, velocityAlert };
  }

  revokeDevice(deviceId: string, actorId: string): DeviceBindingRecord | null {
    for (const [key, rec] of this.devices.entries()) {
      if (rec.id === deviceId) {
        const updated = { ...rec, isRevoked: true };
        this.devices.set(key, updated);
        const actorDevices = this.devicesByActor.get(`${rec.tenantId}:${rec.actorId}`);
        actorDevices?.set(rec.deviceFingerprint, updated);
        this.recordAudit({
          tenantId: rec.tenantId,
          actorId,
          actorRole: "teacher",
          action: "DEVICE_REVOKED",
          targetTable: "device_bindings",
          targetId: deviceId,
          detail: `Remote session revoked for ${rec.actorId} (${rec.deviceLabel})`,
        });
        return updated;
      }
    }
    return null;
  }

  listDevices(tenantId = "demo-centre"): DeviceBindingRecord[] {
    return Array.from(this.devices.values())
      .filter((d) => d.tenantId === tenantId)
      .sort((a, b) => b.lastSeenAtMillis - a.lastSeenAtMillis);
  }

  recordAudit(input: {
    tenantId: string;
    actorId: string;
    actorRole: string;
    action: string;
    targetTable: string;
    targetId: string;
    detail: string;
    beforeState?: unknown;
    afterState?: unknown;
  }): AuditLogEntry {
    const entry: AuditLogEntry = {
      id: `aud-${Date.now()}-${++this.seq}`,
      tenantId: input.tenantId,
      actorId: input.actorId,
      actorRole: input.actorRole,
      action: input.action,
      targetTable: input.targetTable,
      targetId: input.targetId,
      detail: input.detail,
      beforeState: input.beforeState ?? null,
      afterState: input.afterState ?? null,
      createdAtMillis: Date.now(),
    };
    this.auditLogs.push(entry);
    if (this.auditLogs.length > this.maxAuditLogs * 2) {
      this.auditLogs.splice(0, this.auditLogs.length - this.maxAuditLogs);
    }
    return entry;
  }

  listAuditLogs(tenantId = "demo-centre", limit = 100): AuditLogEntry[] {
    const out: AuditLogEntry[] = [];
    for (let i = this.auditLogs.length - 1; i >= 0 && out.length < limit; i--) {
      const log = this.auditLogs[i];
      if (log.tenantId === tenantId) {
        out.push(log);
      }
    }
    return out;
  }
}

export const aegisSecurity = new AegisSecurityService();
