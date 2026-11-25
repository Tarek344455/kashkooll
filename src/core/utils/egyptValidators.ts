import { QrPayloadKind, QrVerifyResult, QrVerifyStatus, StudentQrVerifyResult } from "../../types/kashkool";

// Pure synchronous UTF-8 + SHA-256 + HMAC-SHA256 implementation so 30s QR tokens rotate smoothly on render ticks.
function utf8Bytes(str: string): Uint8Array {
  return new TextEncoder().encode(str);
}

const K256 = new Uint32Array([
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

function rotr(x: number, n: number): number {
  return (x >>> n) | (x << (32 - n));
}

function sha256Bytes(data: Uint8Array): Uint8Array {
  const h = new Uint32Array([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ]);
  const bitLen = data.length * 8;
  const padLen = ((data.length + 8) >> 6) * 64 + 64;
  const padded = new Uint8Array(padLen);
  padded.set(data);
  padded[data.length] = 0x80;
  const view = new DataView(padded.buffer);
  view.setUint32(padLen - 4, bitLen >>> 0, false);
  view.setUint32(padLen - 8, Math.floor(bitLen / 0x100000000), false);

  const w = new Uint32Array(64);
  for (let offset = 0; offset < padLen; offset += 64) {
    for (let i = 0; i < 16; i++) {
      w[i] = view.getUint32(offset + i * 4, false);
    }
    for (let i = 16; i < 64; i++) {
      const s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      const s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) >>> 0;
    }
    let [a, b, c, d, e, f, g, hh] = h;
    for (let i = 0; i < 64; i++) {
      const S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      const ch = (e & f) ^ (~e & g);
      const temp1 = (hh + S1 + ch + K256[i] + w[i]) >>> 0;
      const S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      const maj = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (S0 + maj) >>> 0;
      hh = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }
    h[0] = (h[0] + a) >>> 0;
    h[1] = (h[1] + b) >>> 0;
    h[2] = (h[2] + c) >>> 0;
    h[3] = (h[3] + d) >>> 0;
    h[4] = (h[4] + e) >>> 0;
    h[5] = (h[5] + f) >>> 0;
    h[6] = (h[6] + g) >>> 0;
    h[7] = (h[7] + hh) >>> 0;
  }

  const out = new Uint8Array(32);
  const outView = new DataView(out.buffer);
  for (let i = 0; i < 8; i++) outView.setUint32(i * 4, h[i], false);
  return out;
}

function hmacSha256Bytes(keyRaw: string, message: string): Uint8Array {
  let key = utf8Bytes(keyRaw);
  if (key.length > 64) key = sha256Bytes(key);
  const oPad = new Uint8Array(64);
  const iPad = new Uint8Array(64);
  for (let i = 0; i < 64; i++) {
    const kb = i < key.length ? key[i] : 0;
    oPad[i] = kb ^ 0x5c;
    iPad[i] = kb ^ 0x36;
  }
  const msgBytes = utf8Bytes(message);
  const inner = new Uint8Array(64 + msgBytes.length);
  inner.set(iPad);
  inner.set(msgBytes, 64);
  const innerHash = sha256Bytes(inner);
  const outer = new Uint8Array(64 + 32);
  outer.set(oPad);
  outer.set(innerHash, 64);
  return sha256Bytes(outer);
}

const PHONE_REGEX = /^(?:\+|00)?(?:20)?0?1[0125][0-9]{8}$/;
const QR_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export const EgyptValidators = {
  isValidEgyptianPhone(phone: string): boolean {
    const clean = phone.replace(/[\s\-()]+/g, "");
    return PHONE_REGEX.test(clean);
  },

  normalizeEgyptianPhone(phone: string): string {
    const clean = phone.replace(/[\s\-()]+/g, "");
    if (!this.isValidEgyptianPhone(clean)) return "";
    let digits = clean.replace(/^(\+|00)/, "");
    if (digits.startsWith("20")) digits = digits.slice(2);
    if (digits.startsWith("0")) digits = digits.slice(1);
    return `+20${digits}`;
  },

  formatPiasters(piasters: number, lang: "ar" | "en" = "ar"): string {
    const safe = Math.round(piasters);
    const sign = safe < 0 ? "-" : "";
    const abs = Math.abs(safe);
    const formatted =
      abs % 100 === 0 ? `${sign}${Math.trunc(abs / 100)}` : `${sign}${(abs / 100).toFixed(2)}`;
    return lang === "ar" ? `${formatted} ج.م` : `${formatted} EGP`;
  },

  egpStringToPiasters(raw: string): number | null {
    const value = Number(raw.trim());
    if (!Number.isFinite(value) || value <= 0) return null;
    return Math.round(value * 100);
  },

  sha256Hex(raw: string): string {
    return Array.from(sha256Bytes(utf8Bytes(raw)))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  },

  generateActivationCode(length = 8): string {
    const bytes = new Uint8Array(length);
    if (typeof crypto !== "undefined" && crypto.getRandomValues) {
      crypto.getRandomValues(bytes);
    } else {
      for (let i = 0; i < length; i++) bytes[i] = Math.floor(Math.random() * 256);
    }
    return Array.from(bytes, (b) => QR_ALPHABET[b % QR_ALPHABET.length]).join("");
  },

  normalizeQrCode(raw: string): string {
    return raw.trim().toUpperCase().replace(/[\s-]+/g, "");
  },

  isValidQrActivationCode(raw: string): boolean {
    const clean = this.normalizeQrCode(raw);
    return clean.length >= 6 && clean.length <= 24 && /^[A-Z0-9]+$/.test(clean);
  },

  dataSavingsPercent(originalBytes: number, compressedBytes: number): number {
    if (originalBytes <= 0 || compressedBytes >= originalBytes) return 0;
    return Math.min(99, Math.max(0, Math.floor(((originalBytes - compressedBytes) * 100) / originalBytes)));
  },
};

export class DynamicQrEngine {
  readonly sessionId: string;
  private readonly sessionSecret: string;
  readonly windowSeconds: number;

  constructor(sessionId: string, sessionSecret: string, windowSeconds = 30) {
    this.sessionId = sessionId;
    this.sessionSecret = sessionSecret;
    this.windowSeconds = windowSeconds;
  }

  private hmacHex(payload: string): string {
    return Array.from(hmacSha256Bytes(this.sessionSecret, payload).slice(0, 8))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  }

  private signatureForBucket(targetSessionId: string, bucket: number): string {
    return this.hmacHex(`${targetSessionId}:${bucket}`);
  }

  private studentSignatureForBucket(studentId: string, targetSessionId: string, bucket: number): string {
    return this.hmacHex(`student:${studentId}:${targetSessionId}:${bucket}`);
  }

  tokenAt(epochSeconds = Math.floor(Date.now() / 1000)): string {
    const bucket = Math.floor(epochSeconds / this.windowSeconds);
    const sig = this.signatureForBucket(this.sessionId, bucket);
    return `KSH|${this.sessionId}|${bucket}|${sig}`;
  }

  studentTokenAt(studentId: string, epochSeconds = Math.floor(Date.now() / 1000)): string {
    const bucket = Math.floor(epochSeconds / this.windowSeconds);
    const sig = this.studentSignatureForBucket(studentId, this.sessionId, bucket);
    return `KSHS|${studentId}|${this.sessionId}|${bucket}|${sig}`;
  }

  cardPayloadFor(studentId: string, activationCode: string): string {
    const clean = EgyptValidators.normalizeQrCode(activationCode);
    return `KSHC|${studentId}|${clean}`;
  }

  secondsRemaining(epochSeconds = Math.floor(Date.now() / 1000)): number {
    return this.windowSeconds - (epochSeconds % this.windowSeconds);
  }

  verifyToken(rawToken: string, epochSeconds = Math.floor(Date.now() / 1000)): QrVerifyResult {
    const parts = rawToken.trim().split("|");
    if (parts.length !== 4 || parts[0] !== "KSH") {
      return { status: QrVerifyStatus.INVALID, sessionId: null };
    }
    const tokenSession = parts[1];
    const tokenBucket = Number(parts[2]);
    const tokenSig = parts[3];
    if (!Number.isInteger(tokenBucket)) {
      return { status: QrVerifyStatus.INVALID, sessionId: null };
    }
    if (tokenSession !== this.sessionId) {
      return { status: QrVerifyStatus.INVALID, sessionId: tokenSession };
    }
    const expectedSig = this.signatureForBucket(tokenSession, tokenBucket);
    if (expectedSig.toLowerCase() !== tokenSig.toLowerCase()) {
      return { status: QrVerifyStatus.INVALID, sessionId: tokenSession };
    }
    const currentBucket = Math.floor(epochSeconds / this.windowSeconds);
    return tokenBucket === currentBucket || tokenBucket === currentBucket - 1
      ? { status: QrVerifyStatus.VALID, sessionId: tokenSession }
      : { status: QrVerifyStatus.EXPIRED, sessionId: tokenSession };
  }

  verifyScannedPayload(rawPayload: string, epochSeconds = Math.floor(Date.now() / 1000)): StudentQrVerifyResult {
    const trimmed = rawPayload.trim();
    if (!trimmed) {
      return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.UNKNOWN };
    }
    if (trimmed.startsWith("KSHS|")) {
      const parts = trimmed.split("|");
      if (parts.length !== 5) {
        return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.STUDENT_DYNAMIC };
      }
      const studentId = parts[1].trim();
      const tokenSession = parts[2].trim();
      const tokenBucket = Number(parts[3]);
      const tokenSig = parts[4].trim();
      if (!Number.isInteger(tokenBucket)) {
        return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.STUDENT_DYNAMIC, studentId };
      }
      if (!studentId || tokenSession !== this.sessionId) {
        return {
          status: QrVerifyStatus.INVALID,
          kind: QrPayloadKind.STUDENT_DYNAMIC,
          studentId: studentId || null,
          sessionId: tokenSession,
        };
      }
      const expectedSig = this.studentSignatureForBucket(studentId, tokenSession, tokenBucket);
      if (expectedSig.toLowerCase() !== tokenSig.toLowerCase()) {
        return {
          status: QrVerifyStatus.INVALID,
          kind: QrPayloadKind.STUDENT_DYNAMIC,
          studentId,
          sessionId: tokenSession,
        };
      }
      const currentBucket = Math.floor(epochSeconds / this.windowSeconds);
      const status =
        tokenBucket === currentBucket || tokenBucket === currentBucket - 1
          ? QrVerifyStatus.VALID
          : QrVerifyStatus.EXPIRED;
      return { status, kind: QrPayloadKind.STUDENT_DYNAMIC, studentId, sessionId: tokenSession };
    }
    if (trimmed.startsWith("KSHC|")) {
      const parts = trimmed.split("|");
      if (parts.length !== 3) {
        return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.STUDENT_CARD };
      }
      const studentId = parts[1].trim();
      const cleanCode = EgyptValidators.normalizeQrCode(parts[2]);
      if (studentId && EgyptValidators.isValidQrActivationCode(cleanCode)) {
        return {
          status: QrVerifyStatus.VALID,
          kind: QrPayloadKind.STUDENT_CARD,
          studentId,
          activationCode: cleanCode,
        };
      }
      return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.STUDENT_CARD };
    }
    if (trimmed.startsWith("KSH|")) {
      const gate = this.verifyToken(trimmed, epochSeconds);
      return {
        status: gate.status,
        kind: QrPayloadKind.SESSION_GATE,
        sessionId: gate.sessionId,
      };
    }
    if (EgyptValidators.isValidQrActivationCode(trimmed)) {
      return {
        status: QrVerifyStatus.VALID,
        kind: QrPayloadKind.STUDENT_CARD,
        activationCode: EgyptValidators.normalizeQrCode(trimmed),
      };
    }
    return { status: QrVerifyStatus.INVALID, kind: QrPayloadKind.UNKNOWN };
  }
}
