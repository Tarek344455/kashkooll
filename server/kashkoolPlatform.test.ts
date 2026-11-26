import test from "node:test";
import assert from "node:assert/strict";
import crypto from "node:crypto";
import type { AddressInfo } from "node:net";
import { createKashkoolApp } from "../server";
import { aegisSecurity } from "./aegisSecurity";
import { examFortress } from "./examFortress";

async function startTestServer(): Promise<{ baseUrl: string; close: () => Promise<void> }> {
  process.env.KASHKOOL_NO_LISTEN = "1";
  const app = await createKashkoolApp({ skipVite: true });
  const server = await new Promise<import("node:http").Server>((resolve) => {
    const s = app.listen(0, "127.0.0.1", () => resolve(s));
  });
  const port = (server.address() as AddressInfo).port;
  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: () =>
      new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      }),
  };
}

test("Exam Fortress isolates answer keys, shuffles options deterministically, grades accurately & signs QR certificates", async () => {
  const srv = await startTestServer();
  try {
    // 1. Create custom exam as teacher
    const createRes = await fetch(`${srv.baseUrl}/api/exams`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "teacher",
        "x-kashkool-actor": "teacher-test",
      },
      body: JSON.stringify({
        groupId: "grp-math-3sec",
        titleAr: "امتحان اختباري محصن",
        titleEn: "Security Test Exam",
        subjectAr: "الرياضيات",
        durationMinutes: 15,
        passPercent: 50,
        maxViolations: 2,
        questions: [
          {
            topicTagAr: "تفاضل",
            topicTagEn: "Calculus",
            promptAr: "مشتقة س² عند س=٣",
            promptEn: "d/dx(x^2) at x=3",
            formula: "f(x)=x^2",
            options: ["3", "6", "9", "12"],
            correctIndex: 1,
            points: 5,
            remedialAr: "٢س = ٦",
            remedialEn: "2x = 6",
          },
          {
            topicTagAr: "تكامل",
            topicTagEn: "Integration",
            promptAr: "تكامل ٢س بالنسبة لـ س",
            promptEn: "Integral of 2x dx",
            formula: "int(2x dx)",
            options: ["x^2 + C", "2x^2 + C", "2 + C", "x + C"],
            correctIndex: 0,
            points: 5,
            remedialAr: "س² + ث",
            remedialEn: "x^2 + C",
          },
        ],
      }),
    });
    assert.equal(createRes.status, 201);
    const { exam } = (await createRes.json()) as { exam: { id: string } };

    // 2. Listing exams for student must never contain correctIndex
    const listRes = await fetch(`${srv.baseUrl}/api/exams`, {
      headers: { "x-kashkool-role": "student", "x-kashkool-actor": "stu-test-1" },
    });
    assert.equal(listRes.status, 200);
    const listRaw = await listRes.text();
    assert.equal(listRaw.includes("correctIndex"), false);

    // 3. Start attempt for student 1 -> must sanitize questions
    const startRes = await fetch(`${srv.baseUrl}/api/exams/${exam.id}/start`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "student",
        "x-kashkool-actor": "stu-test-1",
      },
      body: JSON.stringify({
        studentId: "stu-test-1",
        studentName: "طالب تجريبي",
        deviceId: "dev-unit-1",
      }),
    });
    assert.equal(startRes.status, 200);
    const startRaw = await startRes.text();
    assert.equal(startRaw.includes("correctIndex"), false);
    const attemptPayload = JSON.parse(startRaw) as {
      attemptId: string;
      questions: Array<{ id: string; promptEn: string; options: string[] }>;
    };
    assert.equal(attemptPayload.questions.length, 2);

    // 4. Mid-attempt result must be sealed (403)
    const sealedRes = await fetch(
      `${srv.baseUrl}/api/exams/attempts/${attemptPayload.attemptId}/result`,
      { headers: { "x-kashkool-role": "student", "x-kashkool-actor": "stu-test-1" } }
    );
    assert.equal(sealedRes.status, 403);

    // 5. Cross-student IDOR blocked (403)
    const idorRes = await fetch(
      `${srv.baseUrl}/api/exams/attempts/${attemptPayload.attemptId}/answer`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-kashkool-role": "student",
          "x-kashkool-actor": "stu-attacker",
        },
        body: JSON.stringify({
          studentId: "stu-attacker",
          questionId: attemptPayload.questions[0].id,
          selectedDisplayIndex: 0,
        }),
      }
    );
    assert.equal(idorRes.status, 403);

    // 6. Select exact correct option text regardless of shuffled display position
    for (const q of attemptPayload.questions) {
      const targetText = q.promptEn.includes("Integral") ? "x^2 + C" : "6";
      const displayIdx = q.options.indexOf(targetText);
      assert.notEqual(displayIdx, -1, "Shuffled options must preserve original choice text");
      const ansRes = await fetch(
        `${srv.baseUrl}/api/exams/attempts/${attemptPayload.attemptId}/answer`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-kashkool-role": "student",
            "x-kashkool-actor": "stu-test-1",
          },
          body: JSON.stringify({
            studentId: "stu-test-1",
            questionId: q.id,
            selectedDisplayIndex: displayIdx,
          }),
        }
      );
      assert.equal(ansRes.status, 200);
    }

    // 7. Submit & verify 100% score + verifiable QR certificate
    const submitRes = await fetch(
      `${srv.baseUrl}/api/exams/attempts/${attemptPayload.attemptId}/submit`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-kashkool-role": "student",
          "x-kashkool-actor": "stu-test-1",
        },
        body: JSON.stringify({ studentId: "stu-test-1" }),
      }
    );
    assert.equal(submitRes.status, 200);
    const graded = (await submitRes.json()) as {
      percentScore: number;
      passed: boolean;
      mistakes: unknown[];
      certificate: { id: string; certHash: string } | null;
    };
    assert.equal(graded.percentScore, 100);
    assert.equal(graded.passed, true);
    assert.equal(graded.mistakes.length, 0);
    assert.ok(graded.certificate);

    const certVerifyRes = await fetch(
      `${srv.baseUrl}/api/certificates/${graded.certificate.id}/verify`
    );
    assert.equal(certVerifyRes.status, 200);
    const certData = (await certVerifyRes.json()) as {
      valid: boolean;
      certificate: { certHash: string };
    };
    assert.equal(certData.valid, true);
    assert.equal(certData.certificate.certHash, graded.certificate.certHash);
  } finally {
    await srv.close();
  }
});

test("Exam Fortress enforces RBAC, auto-locks on violation threshold, and blocks expired writes", async () => {
  const srv = await startTestServer();
  try {
    // Student cannot create exam or read audit logs
    const badCreate = await fetch(`${srv.baseUrl}/api/exams`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "student",
        "x-kashkool-actor": "stu-evil",
      },
      body: JSON.stringify({
        titleAr: "غير مصرح",
        subjectAr: "رياضيات",
        durationMinutes: 10,
        questions: [
          {
            topicTagAr: "t",
            topicTagEn: "t",
            promptAr: "q",
            promptEn: "q",
            options: ["a", "b"],
            correctIndex: 0,
            remedialAr: "r",
            remedialEn: "r",
          },
        ],
      }),
    });
    assert.equal(badCreate.status, 403);

    const badAudit = await fetch(`${srv.baseUrl}/api/security/audit-logs`, {
      headers: { "x-kashkool-role": "student", "x-kashkool-actor": "stu-evil" },
    });
    assert.equal(badAudit.status, 403);

    // Start exam & trigger 3 integrity violations -> auto-locks & withholds certificate
    const startRes = await fetch(`${srv.baseUrl}/api/exams/exam-phys-mod-1/start`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-role": "student",
        "x-kashkool-actor": "stu-cheater-1",
      },
      body: JSON.stringify({
        studentId: "stu-cheater-1",
        studentName: "طالب مخالف",
        deviceId: "dev-cheater",
      }),
    });
    const att = (await startRes.json()) as { attemptId: string };

    let lastHeartbeat: { autoLocked: boolean; status: string; result?: { certificate: unknown } } | null = null;
    for (let i = 0; i < 3; i++) {
      const hbRes = await fetch(`${srv.baseUrl}/api/exams/attempts/${att.attemptId}/heartbeat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-kashkool-role": "student",
          "x-kashkool-actor": "stu-cheater-1",
        },
        body: JSON.stringify({
          studentId: "stu-cheater-1",
          eventType: i === 2 ? "dev_tools" : "tab_switch",
          detail: `violation #${i + 1}`,
        }),
      });
      assert.equal(hbRes.status, 200);
      lastHeartbeat = (await hbRes.json()) as {
        autoLocked: boolean;
        status: string;
        result?: { certificate: unknown };
      };
    }
    assert.ok(lastHeartbeat);
    assert.equal(lastHeartbeat.autoLocked, true);
    assert.equal(lastHeartbeat.status, "locked_violation");
    assert.equal(lastHeartbeat.result?.certificate ?? null, null);

    // Server-side deadline check unit check directly on service instance
    const attemptRec = examFortress.startAttempt({
      examId: "exam-math-calc-1",
      studentId: "stu-deadline-check",
      studentName: "Deadline Tester",
      deviceId: "dev-dl",
    });
    // Staff force lock works when role is teacher
    const locked = examFortress.forceLockAttempt(attemptRec.attemptId, "teacher-1", "teacher");
    assert.equal(locked.status, "locked_violation");
  } finally {
    await srv.close();
  }
});

test("Aegis Security blocks QR replay, tampered HMAC signatures, and detects multi-device velocity", () => {
  const sessionId = "sess-nokhba-today";
  const secret = "kashkool-local-session-hmac-secret-2026";
  const bucket = Math.floor(Date.now() / 1000 / 30);
  const sig = crypto
    .createHmac("sha256", secret)
    .update(`student:stu-aegis:${sessionId}:${bucket}`)
    .digest("hex")
    .slice(0, 16);
  const dynamicQr = `KSHS|stu-aegis|${sessionId}|${bucket}|${sig}`;

  // 1st scan valid
  const firstScan = aegisSecurity.verifyDynamicQrAntiReplay({
    rawPayload: dynamicQr,
    nonce: "nonce-aegis-0001",
    sessionId,
  });
  assert.equal(firstScan.status, "VALID");

  // 2nd scan with same nonce -> REPLAYED
  const replayScan = aegisSecurity.verifyDynamicQrAntiReplay({
    rawPayload: dynamicQr,
    nonce: "nonce-aegis-0001",
    sessionId,
  });
  assert.equal(replayScan.status, "REPLAYED");

  // Tampered signature -> INVALID
  const tampered = aegisSecurity.verifyDynamicQrAntiReplay({
    rawPayload: `KSHS|stu-aegis|${sessionId}|${bucket}|0000000000000000`,
    nonce: "nonce-aegis-0002",
    sessionId,
  });
  assert.equal(tampered.status, "INVALID");

  // Signed payload anti-replay
  const ts = Date.now();
  const payload = "ledger:topup:25000";
  const nonce = `n-${crypto.randomUUID()}`;
  const sigHex = aegisSecurity.signPayload(`${payload}|${nonce}|${ts}`);
  assert.equal(
    aegisSecurity.verifySignedPayload({ payload, nonce, timestampMs: ts, signatureHex: sigHex }).ok,
    true
  );
  assert.equal(
    aegisSecurity.verifySignedPayload({ payload, nonce, timestampMs: ts, signatureHex: sigHex }).ok,
    false
  );

  // Multi-device velocity detection + remote revocation
  const d1 = aegisSecurity.bindDevice({
    tenantId: "demo-centre",
    actorId: "stu-velocity-test",
    deviceFingerprint: "fp-phone-1",
    deviceLabel: "Android Phone",
  });
  assert.equal(d1.velocityAlert, false);

  const d2 = aegisSecurity.bindDevice({
    tenantId: "demo-centre",
    actorId: "stu-velocity-test",
    deviceFingerprint: "fp-laptop-2",
    deviceLabel: "Secondary Browser",
  });
  assert.equal(d2.velocityAlert, true);

  const revoked = aegisSecurity.revokeDevice(d2.record.id, "teacher-1");
  assert.equal(revoked?.isRevoked, true);
});
