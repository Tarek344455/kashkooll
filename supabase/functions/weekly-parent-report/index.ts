// Weekly parent digest (Friday 18:00 Africa/Cairo via pg_cron).
// Every number is aggregated from real attendance and quiz results. There are
// no placeholder metrics and no per-student spam: exactly one report per week.

import { adminClient } from '../_shared/db.ts';
import { corsHeaders, fail, json } from '../_shared/http.ts';

interface StudentRow { id: string; tenant_id: string; name: string }
interface QuizRow { id: string; tags: string[] | null }

function weekStart(now: Date): string {
  const date = new Date(now);
  const day = date.getUTCDay();
  const mondayOffset = day === 0 ? 6 : day - 1;
  date.setUTCDate(date.getUTCDate() - mondayOffset);
  return date.toISOString().slice(0, 10);
}

function summarize(
  name: string,
  attendanceRate: number,
  averageScore: number,
  weakTags: string[],
): { ar: string; en: string; trajectory: string } {
  const trajectory = averageScore >= 80 ? 'improving'
    : averageScore >= 60 ? 'steady'
    : 'needs_focus';
  const ar = `${name}: حضور ${Math.round(attendanceRate * 100)}٪ هذا الأسبوع، متوسط الدرجات ${averageScore.toFixed(1)}٪.`
    + (weakTags.length ? ` يحتاج مراجعة: ${weakTags.join('، ')}.` : ' لا توجد نقاط ضعف مستمرة.');
  const en = `${name}: attendance ${Math.round(attendanceRate * 100)}% this week, average quiz score ${averageScore.toFixed(1)}%.`
    + (weakTags.length ? ` Review needed: ${weakTags.join(', ')}.` : ' No recurring weak topics.');
  return { ar, en, trajectory };
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return fail('Method not allowed', 405);

  try {
    const db = adminClient();
    const now = new Date();
    const week = weekStart(now);
    const since = new Date(now.getTime() - 7 * 24 * 3600 * 1000).toISOString();
    const quizSince = new Date(now.getTime() - 30 * 24 * 3600 * 1000).toISOString();

    const { data: tenants, error: tenantError } = await db.from('tenants').select('id').eq('is_active', true);
    if (tenantError) throw new Error(tenantError.message);

    let generated = 0;
    for (const tenant of tenants ?? []) {
      const tenantId = tenant.id as string;
      const { data: students, error: studentsError } = await db
        .from('students')
        .select('id,tenant_id,name')
        .eq('tenant_id', tenantId);
      if (studentsError) throw new Error(studentsError.message);

      const { data: quizzes, error: quizzesError } = await db
        .from('quizzes')
        .select('id,tags')
        .eq('tenant_id', tenantId);
      if (quizzesError) throw new Error(quizzesError.message);
      const tagsByQuiz = new Map<string, string[]>(
        (quizzes ?? []).map((quiz: QuizRow) => [quiz.id, quiz.tags ?? []]),
      );

      for (const raw of students ?? []) {
        const student = raw as StudentRow;
        const { data: scans, error: scansError } = await db
          .from('attendance')
          .select('status')
          .eq('tenant_id', tenantId)
          .eq('student_id', student.id)
          .gte('scanned_at', since);
        if (scansError) throw new Error(scansError.message);
        const present = (scans ?? []).filter((scan) => scan.status !== 'absent').length;
        const attendanceRate = scans && scans.length > 0 ? present / scans.length : 0;

        const { data: results, error: resultsError } = await db
          .from('quiz_results')
          .select('score,quiz_id')
          .eq('tenant_id', tenantId)
          .eq('student_id', student.id)
          .gte('taken_at', quizSince);
        if (resultsError) throw new Error(resultsError.message);
        const scores = (results ?? []).map((row) => Number(row.score) || 0);
        const averageScore = scores.length
          ? scores.reduce((sum, score) => sum + score, 0) / scores.length
          : 0;
        const weakTags = new Set<string>();
        for (const row of results ?? []) {
          if (Number(row.score) < 60) {
            for (const tag of tagsByQuiz.get(row.quiz_id as string) ?? []) weakTags.add(tag);
          }
        }

        const summary = summarize(student.name, attendanceRate, averageScore, [...weakTags]);
        const { error: insertError } = await db.from('reports').upsert({
          tenant_id: tenantId,
          student_id: student.id,
          attendance_rate: attendanceRate,
          quiz_score_trajectory: summary.trajectory,
          weak_tags: [...weakTags],
          summary_arabic: summary.ar,
          summary_english: summary.en,
          report_week: week,
        }, { onConflict: 'tenant_id,student_id,report_week' });
        if (insertError) throw new Error(insertError.message);
        generated++;
      }
    }

    return json({ ok: true, week, reports: generated });
  } catch (error) {
    return fail((error as Error).message, 500);
  }
});
