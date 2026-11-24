package com.dig.kashkool.core.firebase

import android.util.Log
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.or.SystemOperatingReport
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.EvaluationTargetType
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.viewmodel.QuizQuestion
import com.google.firebase.Firebase
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.Schema
import com.google.firebase.ai.type.content
import com.google.firebase.ai.type.generationConfig
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withTimeout
import org.json.JSONObject

private const val TAG = "AiOperationsAdvisor"

// gemini-3.8-flash requires NO billing (free tier in Firebase AI Logic)
private const val DEFAULT_MODEL_NAME = "gemini-3.8-flash"

data class AiOperationalBriefing(
    val headline: String,
    val confidenceStatement: String,
    val topDecision: String,
    val nextActionSteps: List<String>,
    val trustGuarantee: String,
)

class AiOperationsAdvisor {

    private val streamingStudyModel by lazy {
        Firebase.ai.generativeModel(
            modelName = DEFAULT_MODEL_NAME,
            systemInstruction = content {
                text(
                    "You are Kashkool's Academic & Operational Advisor in Egypt. " +
                        "Never mention AI/LLM/APIs or pricing jargon. Speak in warm, clear, confident Egyptian Arabic when responding in Arabic, or crisp English when asked in English. " +
                        "Always respect the verified Operations Research numbers provided to you and guide students calmly step by step."
                )
            },
        )
    }

    private val structuredBriefingSchema = Schema.obj(
        properties = mapOf(
            "headline" to Schema.string(description = "Short 1-line executive headline for the user role"),
            "confidenceStatement" to Schema.string(description = "1-2 sentence explanation citing exact OR verified metrics"),
            "topDecision" to Schema.string(description = "Single highest-impact action recommended right now"),
            "nextActionSteps" to Schema.array(
                items = Schema.string(),
                description = "2 to 3 concrete short steps",
            ),
            "trustGuarantee" to Schema.string(description = "Reassuring verification note confirming numbers came from deterministic rules"),
        ),
    )

    private val briefingModel by lazy {
        Firebase.ai.generativeModel(
            modelName = DEFAULT_MODEL_NAME,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = structuredBriefingSchema
            },
        )
    }

    /**
     * Real-time streaming study/operations guidance powered by Firebase AI Logic (`gemini-3.8-flash`).
     * Surfaces authentic exceptions on failure without fabricating responses.
     */
    fun streamStudyGuidance(
        prompt: String,
        role: UserRole,
        subject: String,
        report: SystemOperatingReport,
        lang: AppLanguage,
    ): Flow<String> = flow {
        val langHint = if (lang == AppLanguage.AR) "Arabic (clear Egyptian academic style)" else "English"
        val knapsackTopics = report.studyKnapsack.selectedItems.joinToString(", ") {
            if (lang == AppLanguage.AR) it.titleAr else it.titleEn
        }.ifBlank { if (lang == AppLanguage.AR) "لا توجد موضوعات متأخرة" else "No overdue topics" }

        val fullPrompt = """
            Language: $langHint
            User Role: ${role.key}
            Lesson / Context: $subject
            Verified OR Rescue Plan (0/1 Knapsack 15m): $knapsackTopics (+${report.studyKnapsack.guaranteedGainPercent}% gain)
            System Certainty Score: ${report.certaintyScorePercent}%

            User Question:
            $prompt

            Respond calmly, clearly, and step-by-step. Include numbered steps and a concise rule summary.
        """.trimIndent()

        val accumulated = StringBuilder()
        try {
            withTimeout(60_000L) {
                streamingStudyModel.generateContentStream(fullPrompt).collect { chunk ->
                    val piece = chunk.text.orEmpty()
                    if (piece.isNotEmpty()) {
                        accumulated.append(piece)
                        emit(accumulated.toString())
                    }
                }
            }
            if (accumulated.isBlank()) {
                throw IllegalStateException("Empty response from assistant.")
            }
        } catch (e: TimeoutCancellationException) {
            Log.e(TAG, "Streaming study guidance timed out", e)
            throw e
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Streaming study guidance failed", e)
            throw e
        }
    }

    private val adaptiveQuizSchema = Schema.obj(
        properties = mapOf(
            "questions" to Schema.array(
                items = Schema.obj(
                    properties = mapOf(
                        "topicTag" to Schema.string(),
                        "prompt" to Schema.string(),
                        "formula" to Schema.string(),
                        "options" to Schema.array(items = Schema.string()),
                        "correctIndex" to Schema.integer(),
                        "remedial" to Schema.string(),
                    ),
                ),
                description = "Exactly 3 adaptive multiple-choice high school Egyptian curriculum questions",
            ),
        ),
    )

    private val adaptiveQuizModel by lazy {
        Firebase.ai.generativeModel(
            modelName = DEFAULT_MODEL_NAME,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = adaptiveQuizSchema
            },
        )
    }

    /**
     * Generates 3 custom Egyptian high-school curriculum practice questions for [lessonTitle].
     */
    suspend fun generateAdaptiveQuiz(
        lessonTitle: String,
        lang: AppLanguage,
    ): Result<List<QuizQuestion>> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Arabic (Thanaweya Amma style)" else "Clear English"
        val prompt = """
            Generate 3 high-quality multiple-choice practice questions strictly focused on: "$lessonTitle".
            Output language: $langLabel.
            Each question must include:
            - topicTag: concise skill name
            - prompt: clear question stem
            - formula: key mathematical/physics formula or expression in ASCII/Unicode LTR
            - options: array of exactly 4 short distinct choices
            - correctIndex: 0-based index (0..3) of the right option
            - remedial: brief calm 1-sentence explanation hint if the student misses it.
        """.trimIndent()

        return try {
            val response = withTimeout(60_000L) {
                adaptiveQuizModel.generateContent(prompt)
            }
            val jsonText = response.text ?: throw IllegalStateException("Empty quiz response.")
            val root = JSONObject(jsonText)
            val arr = root.optJSONArray("questions") ?: throw IllegalStateException("Missing questions array.")
            val parsed = buildList {
                for (i in 0 until arr.length()) {
                    val item = arr.optJSONObject(i) ?: continue
                    val optsArr = item.optJSONArray("options") ?: continue
                    val opts = buildList {
                        for (j in 0 until optsArr.length()) {
                            val opt = optsArr.optString(j)
                            if (opt.isNotBlank()) add(opt)
                        }
                    }.take(4)
                    if (opts.size < 2) continue
                    val correctIdx = item.optInt("correctIndex", 0).coerceIn(0, opts.lastIndex)
                    val tag = item.optString("topicTag").ifBlank { lessonTitle }
                    val qPrompt = item.optString("prompt")
                    val formula = item.optString("formula").ifBlank { "f(x)" }
                    val hint = item.optString("remedial")
                    if (qPrompt.isBlank()) continue
                    add(
                        QuizQuestion(
                            id = "ai-q-${System.currentTimeMillis()}-$i",
                            topicTagAr = tag,
                            topicTagEn = tag,
                            promptAr = qPrompt,
                            promptEn = qPrompt,
                            formula = formula,
                            options = opts,
                            correctIndex = correctIdx,
                            remedialAr = hint,
                            remedialEn = hint,
                        )
                    )
                }
            }
            if (parsed.isEmpty()) {
                Result.failure(IllegalStateException("Could not parse generated quiz questions."))
            } else {
                Result.success(parsed)
            }
        } catch (e: TimeoutCancellationException) {
            Log.e(TAG, "Adaptive quiz generation timed out", e)
            Result.failure(e)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Adaptive quiz generation failed", e)
            Result.failure(e)
        }
    }

    /**
     * Generates a structured JSON operational briefing grounded in deterministic OR metrics.
     */
    suspend fun generateOperationalBriefing(
        report: SystemOperatingReport,
        role: UserRole,
        lang: AppLanguage,
    ): Result<AiOperationalBriefing> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Commercial Arabic (RTL)" else "Clear English"
        val netFormatted = EgyptValidators.formatPiasters(report.financialCertainty.netPayoutPiasters, lang.code)
        val prompt = """
            Output strictly in $langLabel.
            Role: ${role.key}
            Exact Verified Operations Research Metrics (DO NOT alter these numbers):
            - Operational Certainty Index: ${report.certaintyScorePercent}%
            - Hall Utilization: ${report.groupAllocation.utilizationPercent}% (${report.groupAllocation.totalEnrolled}/${report.groupAllocation.totalCapacity} seats)
            - Recommended Seat Shift: ${report.groupAllocation.recommendedSeatShift}
            - Break-Even Attendance: ${report.financialCertainty.breakEvenAttendance} vs Attended: ${report.financialCertainty.attendedCount} (Safety Margin: ${report.financialCertainty.marginOfSafetyPercent}%)
            - Net Teacher Payout: $netFormatted
            - Ledger Balanced: ${report.financialCertainty.ledgerBalanced}
            - Queue Lanes: ${report.queueDispatch.activeLanes}, Expected Wait: ${report.queueDispatch.expectedWaitSeconds}s
            - Study Knapsack 15-min Optimal Gain: +${report.studyKnapsack.guaranteedGainPercent}%
            - Hall/Resource Status: ${report.resourceConflict.summaryEn}

            Summarize the single best decision and 2-3 immediate trust-building actions for this user role without using technical jargon like AI/LLM/API.
        """.trimIndent()

        return try {
            val response = withTimeout(60_000L) {
                briefingModel.generateContent(prompt)
            }
            val jsonText = response.text ?: throw IllegalStateException("Empty JSON briefing response.")
            val obj = JSONObject(jsonText)
            val stepsArr = obj.optJSONArray("nextActionSteps")
            val steps = buildList {
                if (stepsArr != null) {
                    for (i in 0 until stepsArr.length()) {
                        val s = stepsArr.optString(i)
                        if (s.isNotBlank()) add(s)
                    }
                }
            }
            Result.success(
                AiOperationalBriefing(
                    headline = obj.optString("headline"),
                    confidenceStatement = obj.optString("confidenceStatement"),
                    topDecision = obj.optString("topDecision"),
                    nextActionSteps = steps,
                    trustGuarantee = obj.optString("trustGuarantee"),
                )
            )
        } catch (e: TimeoutCancellationException) {
            Log.e(TAG, "Operational briefing timed out", e)
            Result.failure(e)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Operational briefing failed", e)
            Result.failure(e)
        }
    }

    private val performanceEvaluationSchema = Schema.obj(
        properties = mapOf(
            "overallScore" to Schema.integer(description = "Integer performance score between 40 and 100"),
            "trustBadge" to Schema.string(description = "Short 3-5 word verification badge label without technical jargon"),
            "analyticalSummary" to Schema.string(description = "2-3 analytical sentences grounded in the verified metrics"),
            "instantFeedback" to Schema.string(description = "Warm, immediate 1-2 sentence motivating takeaway"),
            "strengths" to Schema.array(
                items = Schema.string(),
                description = "2 to 3 verified strength bullet points",
            ),
            "improvementAreas" to Schema.array(
                items = Schema.string(),
                description = "1 to 2 constructive improvement points",
            ),
            "nextActionPlan" to Schema.array(
                items = Schema.string(),
                description = "2 to 3 concrete immediate next steps",
            ),
            "trustVerificationNote" to Schema.string(description = "Transparent statement explaining which verified records support this evaluation"),
        ),
    )

    private val evaluationModel by lazy {
        Firebase.ai.generativeModel(
            modelName = DEFAULT_MODEL_NAME,
            systemInstruction = content {
                text(
                    "You are Kashkool's Academic Evaluation & Trust Specialist in Egypt. " +
                        "Deliver calm, honest, analytical evaluations that build certainty between students, parents, teachers, and center owners. " +
                        "Never use buzzwords like AI, LLM, bot, API, or pricing jargon. Always cite exact verified figures provided in the prompt."
                )
            },
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = performanceEvaluationSchema
            },
        )
    }

    suspend fun evaluateStudentPerformance(
        student: StudentEntity,
        groupName: String,
        attendedSessionsCount: Int,
        completedLessonsCount: Int,
        weakTopicTitles: List<String>,
        lang: AppLanguage,
    ): Result<PerformanceEvaluationEntity> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Arabic (RTL)" else "Clear English"
        val studentName = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
        val walletFormatted = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang.code)
        val duesFormatted = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang.code)
        val weakList = weakTopicTitles.takeIf { it.isNotEmpty() }?.joinToString(", ") ?: "None"

        val prompt = """
            Output strictly in $langLabel.
            Evaluate STUDENT academic & commitment performance based ONLY on these verified Kashkool records:
            - Student Name: $studentName
            - Group: $groupName
            - Current Mastery Score: ${student.masteryPercent}%
            - Attendance Streak Days: ${student.streakDays}
            - Recorded Check-ins: $attendedSessionsCount
            - Completed Digital Lessons: $completedLessonsCount
            - Pending Remedial Topics: $weakList
            - Session Wallet Balance: $walletFormatted (Pending Dues: $duesFormatted)

            Provide an encouraging, transparent, evidence-backed evaluation with concrete strengths, constructive growth areas, and immediate next steps.
        """.trimIndent()

        return runEvaluationInference(
            targetId = student.id,
            targetName = studentName,
            targetType = EvaluationTargetType.STUDENT,
            lang = lang,
            prompt = prompt,
        )
    }

    suspend fun evaluateTeacherPerformance(
        teacherLabel: String,
        report: SystemOperatingReport,
        studentCount: Int,
        avgStudentMastery: Int,
        pendingReceiptsCount: Int,
        lang: AppLanguage,
    ): Result<PerformanceEvaluationEntity> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Arabic (RTL)" else "Clear English"
        val netFormatted = EgyptValidators.formatPiasters(report.financialCertainty.netPayoutPiasters, lang.code)

        val prompt = """
            Output strictly in $langLabel.
            Evaluate TEACHER & EDUCATIONAL CENTER performance based ONLY on these verified Kashkool records:
            - Teacher / Center: $teacherLabel
            - Total Enrolled Students: $studentCount (Average Mastery: $avgStudentMastery%)
            - Hall Utilization: ${report.groupAllocation.utilizationPercent}% (${report.groupAllocation.totalEnrolled}/${report.groupAllocation.totalCapacity} seats)
            - Today's Attendance: ${report.financialCertainty.attendedCount} vs Break-Even: ${report.financialCertainty.breakEvenAttendance} (Safety Margin: ${report.financialCertainty.marginOfSafetyPercent}%)
            - Net Verified Payout: $netFormatted (Ledger Balanced: ${report.financialCertainty.ledgerBalanced})
            - Hall & Resource Readiness: ${report.resourceConflict.summaryEn}
            - Operational Certainty Index: ${report.certaintyScorePercent}%
            - Pending Payment Receipts Queue: $pendingReceiptsCount

            Provide an analytical, transparent evaluation highlighting instructional impact, operational discipline, hall management, and trust-building next steps.
        """.trimIndent()

        return runEvaluationInference(
            targetId = "teacher-center",
            targetName = teacherLabel,
            targetType = EvaluationTargetType.TEACHER,
            lang = lang,
            prompt = prompt,
        )
    }

    private suspend fun runEvaluationInference(
        targetId: String,
        targetName: String,
        targetType: EvaluationTargetType,
        lang: AppLanguage,
        prompt: String,
    ): Result<PerformanceEvaluationEntity> {
        return try {
            val response = withTimeout(60_000L) {
                evaluationModel.generateContent(prompt)
            }
            val jsonText = response.text ?: throw IllegalStateException("Empty evaluation response.")
            val obj = JSONObject(jsonText)

            fun readArray(key: String): List<String> {
                val arr = obj.optJSONArray(key) ?: return emptyList()
                return buildList {
                    for (i in 0 until arr.length()) {
                        val s = arr.optString(i).trim()
                        if (s.isNotEmpty()) add(s)
                    }
                }
            }

            val summary = obj.optString("analyticalSummary").trim()
            val feedback = obj.optString("instantFeedback").trim()
            if (summary.isBlank() || feedback.isBlank()) {
                throw IllegalStateException("Incomplete evaluation fields.")
            }

            Result.success(
                PerformanceEvaluationEntity(
                    id = "eval-${targetType.key}-$targetId",
                    targetId = targetId,
                    targetName = targetName,
                    targetType = targetType,
                    languageCode = lang.code,
                    overallScore = obj.optInt("overallScore", 80).coerceIn(40, 100),
                    trustBadge = obj.optString("trustBadge").trim(),
                    analyticalSummary = summary,
                    instantFeedback = feedback,
                    strengths = readArray("strengths"),
                    improvementAreas = readArray("improvementAreas"),
                    nextActionPlan = readArray("nextActionPlan"),
                    trustVerificationNote = obj.optString("trustVerificationNote").trim(),
                    evaluatedAtMillis = System.currentTimeMillis(),
                )
            )
        } catch (e: TimeoutCancellationException) {
            Log.e(TAG, "Performance evaluation timed out", e)
            Result.failure(e)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Performance evaluation failed", e)
            Result.failure(e)
        }
    }
}
