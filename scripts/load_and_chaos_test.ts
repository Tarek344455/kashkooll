import assert from "node:assert/strict";
import crypto from "node:crypto";
import type { AddressInfo } from "node:net";
import { performance } from "node:perf_hooks";
import { createKashkoolApp } from "../server";
import { aegisSecurity } from "../server/aegisSecurity";

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return Number(sorted[idx].toFixed(2));
}

async function run() {
  process.env.KASHKOOL_NO_LISTEN = "1";
  const app = await createKashkoolApp({ skipVite: true });
  const server = await new Promise<import("node:http").Server>((resolve) => {
    const s = app.listen(0, "127.0.0.1", () => resolve(s));
  });

  const port = (server.address() as AddressInfo).port;
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    // =========================================================================
    // PHASE 1: MASSIVE-SCALE CONCURRENCY EXAM & ANTI-REPLAY LOAD TEST
    // 2,500 Virtual Students -> Start + 4 Answer Saves + Submit (15,000 Requests)
    // =========================================================================
    await fetch(`${baseUrl}/api/health`);

    const totalStudents = 2500;
    const waveSize = 80;
    const latenciesMs: number[] = [];
    let totalRequests = 0;
    let failedRequests = 0;
    let passedGradedCount = 0;

    async function timedFetch(url: string, init: RequestInit): Promise<Response> {
      const t0 = performance.now();
      const res = await fetch(url, init);
      const dt = performance.now() - t0;
      latenciesMs.push(dt);
      totalRequests += 1;
      if (!res.ok) {
        failedRequests += 1;
      }
      return res;
    }

    const loadStartMs = performance.now();

    for (let offset = 0; offset < totalStudents; offset += waveSize) {
      const wavePromises: Array<Promise<void>> = [];
      for (let i = offset; i < Math.min(totalStudents, offset + waveSize); i++) {
        const studentId = `load-stu-${String(i + 1).padStart(4, "0")}`;
        wavePromises.push(
          (async () => {
            const headers = {
              "Content-Type": "application/json",
              "x-kashkool-role": "student",
              "x-kashkool-actor": studentId,
            };

            const startRes = await timedFetch(`${baseUrl}/api/exams/exam-math-calc-1/start`, {
              method: "POST",
              headers,
              body: JSON.stringify({
                studentId,
                studentName: `Student ${i + 1}`,
                deviceId: `dev-${studentId}`,
              }),
            });
            const started = (await startRes.json()) as {
              attemptId: string;
              questions: Array<{ id: string; options: string[] }>;
            };

            for (let qi = 0; qi < started.questions.length; qi++) {
              const q = started.questions[qi];
              await timedFetch(`${baseUrl}/api/exams/attempts/${started.attemptId}/answer`, {
                method: "POST",
                headers,
                body: JSON.stringify({
                  studentId,
                  questionId: q.id,
                  selectedDisplayIndex: i % q.options.length,
                  deviceId: `dev-${studentId}`,
                }),
              });
            }

            const subRes = await timedFetch(
              `${baseUrl}/api/exams/attempts/${started.attemptId}/submit`,
              {
                method: "POST",
                headers,
                body: JSON.stringify({ studentId }),
              }
            );
            if (subRes.ok) {
              const graded = (await subRes.json()) as { status: string };
              if (graded.status === "submitted") passedGradedCount += 1;
            }
          })()
        );
      }
      await Promise.all(wavePromises);
    }

    const loadDurationMs = performance.now() - loadStartMs;
    const sortedLat = [...latenciesMs].sort((a, b) => a - b);
    const p50Ms = percentile(sortedLat, 50);
    const p95Ms = percentile(sortedLat, 95);
    const p99Ms = percentile(sortedLat, 99);
    const rps = Math.round((totalRequests / loadDurationMs) * 1000);

    assert.equal(failedRequests, 0, `Expected 0 failed HTTP requests, got ${failedRequests}`);
    assert.equal(passedGradedCount, totalStudents, "All 2,500 student exams must submit cleanly");
    assert.ok(p95Ms <= 200, `SLA breach: p95=${p95Ms}ms > 200ms`);

    // =========================================================================
    // PHASE 2: ADVERSARIAL PENETRATION & CHAOS VERIFICATION
    // =========================================================================
    const securityChecks: Array<{ probe: string; passed: boolean; detail: string }> = [];

    // Probe 1: Answer Key Isolation
    const examsListRes = await fetch(`${baseUrl}/api/exams`, {
      headers: { "x-kashkool-role": "student", "x-kashkool-actor": "probe-stu" },
    });
    const examsListText = await examsListRes.text();
    const probeStartRes = await fetch(`${baseUrl}/api/exams/exam-math-calc-1/start`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "student",
        "x-kashkool-actor": "probe-stu",
      },
      body: JSON.stringify({ studentId: "probe-stu", studentName: "Probe", deviceId: "dev-probe" }),
    });
    const probeStartText = await probeStartRes.text();
    const probeAttempt = JSON.parse(probeStartText) as {
      attemptId: string;
      questions: Array<{ id: string }>;
    };
    const keyLeakClean =
      !examsListText.includes("correctIndex") && !probeStartText.includes("correctIndex");
    assert.equal(keyLeakClean, true);
    securityChecks.push({
      probe: "Key Isolation Probe",
      passed: keyLeakClean,
      detail: "Zero answer keys exposed in listings or started attempt JSON",
    });

    // Probe 2: Role Escalation Blocked (403)
    const escExam = await fetch(`${baseUrl}/api/exams`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-kashkool-role": "student" },
      body: JSON.stringify({ titleAr: "اختراق", questions: [{ promptAr: "q", options: ["1", "2"] }] }),
    });
    const escProctor = await fetch(`${baseUrl}/api/exams/exam-math-calc-1/attempts`, {
      headers: { "x-kashkool-role": "student" },
    });
    const escAudit = await fetch(`${baseUrl}/api/security/audit-logs`, {
      headers: { "x-kashkool-role": "student" },
    });
    const escRevoke = await fetch(`${baseUrl}/api/security/device/revoke`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-kashkool-role": "student" },
      body: JSON.stringify({ deviceId: "dev-1" }),
    });
    const rbacClean =
      escExam.status === 403 &&
      escProctor.status === 403 &&
      escAudit.status === 403 &&
      escRevoke.status === 403;
    assert.equal(rbacClean, true);
    securityChecks.push({
      probe: "RBAC Privilege Escalation",
      passed: rbacClean,
      detail: "All 4 staff routes rejected student token with HTTP 403",
    });

    // Probe 3: Cross-Student IDOR Blocked
    const idorAns = await fetch(`${baseUrl}/api/exams/attempts/${probeAttempt.attemptId}/answer`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "student",
        "x-kashkool-actor": "attacker-stu",
      },
      body: JSON.stringify({
        studentId: "attacker-stu",
        questionId: probeAttempt.questions[0].id,
        selectedDisplayIndex: 0,
      }),
    });
    const idorResult = await fetch(
      `${baseUrl}/api/exams/attempts/${probeAttempt.attemptId}/result`,
      { headers: { "x-kashkool-role": "student", "x-kashkool-actor": "attacker-stu" } }
    );
    const idorBlocked = idorAns.status === 403 && idorResult.status === 403;
    assert.equal(idorBlocked, true);
    securityChecks.push({
      probe: "Cross-Student IDOR",
      passed: idorBlocked,
      detail: "Cross-student answer mutation and result read blocked with HTTP 403",
    });

    // Probe 4: Violation Auto-Lock
    let lockedOut = false;
    for (let v = 0; v < 3; v++) {
      const res = await fetch(`${baseUrl}/api/exams/attempts/${probeAttempt.attemptId}/heartbeat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-kashkool-role": "student",
          "x-kashkool-actor": "probe-stu",
        },
        body: JSON.stringify({
          studentId: "probe-stu",
          eventType: v === 2 ? "dev_tools" : "tab_switch",
          detail: "chaos breach",
        }),
      });
      const body = (await res.json()) as { autoLocked: boolean; status: string };
      if (body.autoLocked && body.status === "locked_violation") {
        lockedOut = true;
      }
    }
    assert.equal(lockedOut, true);
    securityChecks.push({
      probe: "Integrity Auto-Lock",
      passed: lockedOut,
      detail: "Attempt automatically locked & finalized at 3rd security event",
    });

    // Probe 5: Dynamic QR Anti-Replay & Signature Tamper
    const sessionId = "sess-nokhba-today";
    const bucket = Math.floor(Date.now() / 1000 / 30);
    const sig = crypto
      .createHmac("sha256", "kashkool-local-session-hmac-secret-2026")
      .update(`student:stu-chaos:${sessionId}:${bucket}`)
      .digest("hex")
      .slice(0, 16);
    const qrToken = `KSHS|stu-chaos|${sessionId}|${bucket}|${sig}`;
    const qr1Res = await fetch(`${baseUrl}/api/security/qr/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ rawPayload: qrToken, nonce: "chaos-qr-nonce-1", sessionId }),
    });
    const qr2Res = await fetch(`${baseUrl}/api/security/qr/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ rawPayload: qrToken, nonce: "chaos-qr-nonce-1", sessionId }),
    });
    const qrTamperRes = await fetch(`${baseUrl}/api/security/qr/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        rawPayload: `KSHS|stu-chaos|${sessionId}|${bucket}|ffffffffffffffff`,
        nonce: "chaos-qr-nonce-2",
        sessionId,
      }),
    });
    const qr1 = (await qr1Res.json()) as { status: string };
    const qr2 = (await qr2Res.json()) as { status: string };
    const qrTamper = (await qrTamperRes.json()) as { status: string };
    const qrAntiReplayOk =
      qr1.status === "VALID" && qr2.status === "REPLAYED" && qrTamper.status === "INVALID";
    assert.equal(qrAntiReplayOk, true);
    securityChecks.push({
      probe: "QR Anti-Replay & Tamper",
      passed: qrAntiReplayOk,
      detail: "1st=VALID, replay=REPLAYED, tampered=INVALID",
    });

    // Probe 6: HMAC Signed Payload Nonce Anti-Replay
    const ts = Date.now();
    const payloadStr = "exam:submit:critical";
    const pNonce = `chaos-${crypto.randomUUID()}`;
    const pSig = aegisSecurity.signPayload(`${payloadStr}|${pNonce}|${ts}`);
    const firstSig = aegisSecurity.verifySignedPayload({
      payload: payloadStr,
      nonce: pNonce,
      timestampMs: ts,
      signatureHex: pSig,
    });
    const replaySig = aegisSecurity.verifySignedPayload({
      payload: payloadStr,
      nonce: pNonce,
      timestampMs: ts,
      signatureHex: pSig,
    });
    const hmacOk = firstSig.ok && !replaySig.ok;
    assert.equal(hmacOk, true);
    securityChecks.push({
      probe: "HMAC Nonce Anti-Replay",
      passed: hmacOk,
      detail: "Monotonic nonce accepted once, rejected on replay",
    });

    // Probe 7: Multi-Device Velocity & Staff Revocation
    const devA = await fetch(`${baseUrl}/api/security/device/bind`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tenantId: "demo-centre",
        actorId: "stu-chaos-vel",
        deviceFingerprint: "fp-chaos-a",
        deviceLabel: "Device A",
      }),
    });
    const devB = await fetch(`${baseUrl}/api/security/device/bind`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tenantId: "demo-centre",
        actorId: "stu-chaos-vel",
        deviceFingerprint: "fp-chaos-b",
        deviceLabel: "Device B",
      }),
    });
    const devAData = (await devA.json()) as { velocityAlert: boolean };
    const devBData = (await devB.json()) as { record: { id: string }; velocityAlert: boolean };
    const revRes = await fetch(`${baseUrl}/api/security/device/revoke`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "teacher",
        "x-kashkool-actor": "teacher-1",
      },
      body: JSON.stringify({ deviceId: devBData.record.id }),
    });
    const revData = (await revRes.json()) as { revoked: { isRevoked: boolean } };
    const deviceOk = !devAData.velocityAlert && devBData.velocityAlert && revData.revoked.isRevoked;
    assert.equal(deviceOk, true);
    securityChecks.push({
      probe: "Device Velocity & Remote Revoke",
      passed: deviceOk,
      detail: "Concurrent second device flagged & remotely revoked by teacher",
    });

    const summary = {
      loadTest: {
        virtualStudents: totalStudents,
        completedSubmissions: passedGradedCount,
        totalHttpRequests: totalRequests,
        failedRequests,
        durationMs: Number(loadDurationMs.toFixed(1)),
        throughputRps: rps,
        latencyMs: { p50: p50Ms, p95: p95Ms, p99: p99Ms },
        slaPassed: p95Ms <= 200 && failedRequests === 0,
      },
      securityProbesPassed: `${securityChecks.filter((c) => c.passed).length}/${securityChecks.length}`,
      securityChecks,
    };

    console.log(JSON.stringify(summary, null, 2));
  } finally {
    await new Promise<void>((resolve, reject) => {
      server.close((err) => (err ? reject(err) : resolve()));
    });
  }
}

run().catch((err) => {
  console.error("LOAD/CHAOS TEST FAILED:", err);
  process.exit(1);
});
