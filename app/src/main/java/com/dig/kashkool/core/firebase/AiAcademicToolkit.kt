package com.dig.kashkool.core.firebase

import android.graphics.Bitmap
import android.util.Log
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.or.StudentOrProfile
import com.dig.kashkool.core.or.SystemOperatingReport
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.viewmodel.AssistantMessage
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
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

private const val TOOLKIT_TAG = "AiAcademicToolkit"
private const val FLASH_MODEL = "gemini-3.8-flash"
private const val FLASH_LITE_MODEL = "gemini-3.5-flash-lite"

@Serializable
data class ReceiptScanResult(
    val amountEgp: String = "",
    val referenceNumber: String = "",
    val detectedChannelType: String = "",
    val clarityStatus: String = "medium",
    val verificationNote: String = "",
)

@Serializable
data class StudyFlashcard(
    val front: String = "",
    val back: String = "",
)

@Serializable
data class LessonRevisionDeck(
    val lessonTitle: String = "",
    val memoryHook: String = "",
    val flashcards: List<StudyFlashcard> = emptyList(),
    val commonTraps: List<String> = emptyList(),
)

@Serializable
data class ParentWeeklyDigest(
    val headline: String = "",
    val weeklyNarrative: String = "",
    val cheerMessage: String = "",
    val homeSupportTip: String = "",
)

@Serializable
data class SecretaryNoticeDraft(
    val toneTag: String = "",
    val messageText: String = "",
)

@Serializable
data class TeacherLessonPlan(
    val topicTitle: String = "",
    val pacingSteps: List<String> = emptyList(),
    val basicHomework: List<String> = emptyList(),
    val challengeHomework: List<String> = emptyList(),
    val assistantChecklist: List<String> = emptyList(),
)

class AiAcademicToolkit {

    internal val jsonParser = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
    }

    private val studyChatModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_MODEL,
            systemInstruction = content {
                text(
                    "You are Kashkool's Academic & Operational Advisor in Egypt. " +
                        "Never mention AI/LLM/APIs or pricing jargon. Speak in warm, clear Egyptian Arabic when responding in Arabic, or crisp English when asked in English. " +
                        "When given a student's handwritten or textbook problem photo, transcribe the equation/diagram carefully and walk through the exact solution step by step."
                )
            },
        )
    }

    private val receiptScanSchema = Schema.obj(
        properties = mapOf(
            "amountEgp" to Schema.string(description = "Numeric EGP amount string like 240 or 125.50, empty if unreadable"),
            "referenceNumber" to Schema.string(description = "Transfer reference or receipt ID found in image, empty if unreadable"),
            "detectedChannelType" to Schema.enumeration(
                values = listOf("insta_pay", "vodafone_cash", "etisalat_cash", "orange_cash", "we_pay", "fawry", "cash_desk", "unknown"),
                description = "Detected Egyptian payment provider",
            ),
            "clarityStatus" to Schema.enumeration(
                values = listOf("high", "medium", "low"),
                description = "Receipt image readability and authenticity confidence",
            ),
            "verificationNote" to Schema.string(description = "Short note explaining what was detected or if anything is blurry/missing"),
        ),
    )

    private val receiptScanModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_MODEL,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = receiptScanSchema
            },
        )
    }

    private val revisionDeckSchema = Schema.obj(
        properties = mapOf(
            "lessonTitle" to Schema.string(),
            "memoryHook" to Schema.string(description = "Memorable 1-2 sentence rule/mnemonic summarizing the whole lesson"),
            "flashcards" to Schema.array(
                items = Schema.obj(
                    properties = mapOf(
                        "front" to Schema.string(description = "Concept, law name, or quick question"),
                        "back" to Schema.string(description = "Concise formula + solution tip"),
                    ),
                ),
                description = "4 concise active-recall flashcards",
            ),
            "commonTraps" to Schema.array(
                items = Schema.string(),
                description = "2 to 3 common Egyptian exam mistakes to avoid",
            ),
        ),
    )

    private val revisionDeckModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_MODEL,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = revisionDeckSchema
            },
        )
    }

    private val parentDigestSchema = Schema.obj(
        properties = mapOf(
            "headline" to Schema.string(description = "Short warm weekly headline for the parent"),
            "weeklyNarrative" to Schema.string(description = "2-3 empathetic sentences citing exact mastery, attendance, and balance"),
            "cheerMessage" to Schema.string(description = "Ready-to-send WhatsApp encouragement text from parent to student"),
            "homeSupportTip" to Schema.string(description = "1 practical 10-minute home support tip"),
        ),
    )

    private val parentDigestModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_MODEL,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = parentDigestSchema
            },
        )
    }

    private val secretaryNoticeSchema = Schema.obj(
        properties = mapOf(
            "toneTag" to Schema.string(description = "Short 2-word tone label like متابعة لطيفة or تذكير رسمي"),
            "messageText" to Schema.string(description = "Polite, dignified WhatsApp notice ready to send to parent/student"),
        ),
    )

    private val secretaryNoticeModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_LITE_MODEL,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = secretaryNoticeSchema
            },
        )
    }

    private val teacherPlanSchema = Schema.obj(
        properties = mapOf(
            "topicTitle" to Schema.string(),
            "pacingSteps" to Schema.array(items = Schema.string(), description = "4 timed steps for a 90-minute center lecture"),
            "basicHomework" to Schema.array(items = Schema.string(), description = "2 foundational practice tasks"),
            "challengeHomework" to Schema.array(items = Schema.string(), description = "2 high-skill Thanaweya Amma topper problems"),
            "assistantChecklist" to Schema.array(items = Schema.string(), description = "2 quick prep tasks for teaching assistants"),
        ),
    )

    private val teacherPlanModel by lazy {
        Firebase.ai.generativeModel(
            modelName = FLASH_MODEL,
            generationConfig = generationConfig {
                responseMimeType = "application/json"
                responseSchema = teacherPlanSchema
            },
        )
    }

    /**
     * Multi-turn streaming tutor supporting both conversation history (`startChat`) and optional
     * multimodal problem photo inspection (`content { image(bitmap); text(...) }`).
     */
    fun streamMultiTurnStudyOrPhoto(
        prompt: String,
        history: List<AssistantMessage>,
        problemBitmap: Bitmap?,
        role: UserRole,
        subject: String,
        report: SystemOperatingReport,
        lang: AppLanguage,
    ): Flow<String> = flow {
        val langHint = if (lang == AppLanguage.AR) "Arabic (clear Egyptian academic style)" else "English"
        val knapsackTopics = report.studyKnapsack.selectedItems.joinToString(", ") {
            if (lang == AppLanguage.AR) it.titleAr else it.titleEn
        }.ifBlank { if (lang == AppLanguage.AR) "لا توجد موضوعات متأخرة" else "No overdue topics" }

        val contextualPrompt = """
            Language: $langHint
            User Role: ${role.key}
            Lesson / Context: $subject
            Verified 15-min Rescue Focus: $knapsackTopics (+${report.studyKnapsack.guaranteedGainPercent}% gain)
            System Certainty Score: ${report.certaintyScorePercent}%

            Question / Request:
            $prompt

            Respond calmly with numbered steps and a concise rule takeaway.
        """.trimIndent()

        val accumulated = StringBuilder()
        try {
            withTimeout(60_000L) {
                val stream = if (problemBitmap != null) {
                    val recentSummary = history.takeLast(4).joinToString("\n") {
                        val speaker = if (it.fromUser) "User" else "Advisor"
                        "$speaker: ${it.text.take(240)}"
                    }
                    studyChatModel.generateContentStream(
                        content {
                            image(problemBitmap)
                            if (recentSummary.isNotBlank()) {
                                text("Recent conversation context:\n$recentSummary")
                            }
                            text(contextualPrompt)
                        }
                    )
                } else {
                    val chatHistory = history.drop(1).takeLast(10).map { msg ->
                        content(if (msg.fromUser) "user" else "model") {
                            text(msg.text)
                        }
                    }
                    val chat = studyChatModel.startChat(history = chatHistory)
                    chat.sendMessageStream(contextualPrompt)
                }

                stream.collect { chunk ->
                    val piece = chunk.text.orEmpty()
                    if (piece.isNotEmpty()) {
                        accumulated.append(piece)
                        emit(accumulated.toString())
                    }
                }
            }
            if (accumulated.isBlank()) {
                throw IllegalStateException("Empty response from study helper.")
            }
        } catch (e: TimeoutCancellationException) {
            Log.e(TOOLKIT_TAG, "Multi-turn study stream timed out", e)
            throw e
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TOOLKIT_TAG, "Multi-turn study stream failed", e)
            throw e
        }
    }

    /**
     * Multimodal payment receipt extraction for Egyptian channels (InstaPay, Vodafone Cash, Fawry, Cash).
     */
    suspend fun scanPaymentReceipt(
        bitmap: Bitmap,
        lang: AppLanguage,
    ): Result<ReceiptScanResult> {
        val langLabel = if (lang == AppLanguage.AR) "Arabic (Egyptian concise phrasing)" else "English"
        val prompt = """
            Inspect this Egyptian payment transfer receipt screenshot or photo carefully.
            Extract:
            - amountEgp: only digits and optional decimal point (e.g. "240" or "125.50"), empty if not visible.
            - referenceNumber: transaction/operation reference number, empty if not visible.
            - detectedChannelType: one of insta_pay, vodafone_cash, etisalat_cash, orange_cash, we_pay, fawry, cash_desk, unknown.
            - clarityStatus: high, medium, or low.
            - verificationNote: 1 concise sentence in $langLabel explaining readability or missing fields.
        """.trimIndent()

        return runStructuredCall(receiptScanModel, prompt, bitmap) { jsonText ->
            jsonParser.decodeFromString<ReceiptScanResult>(jsonText)
        }
    }

    /**
     * Generates active-recall flashcards and exam trap warnings for a lecture.
     */
    suspend fun generateLessonRevisionDeck(
        lessonTitle: String,
        lessonSummary: String,
        lang: AppLanguage,
    ): Result<LessonRevisionDeck> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Arabic (Thanaweya Amma)" else "Clear English"
        val prompt = """
            Output strictly in $langLabel.
            Build a lightweight, high-retention 5-minute revision deck for:
            Lesson: "$lessonTitle"
            Key Notes: "$lessonSummary"

            Include 4 active-recall flashcards (front + concise back), 2-3 common Egyptian exam traps, and 1 memorable hook.
        """.trimIndent()

        return runStructuredCall(revisionDeckModel, prompt) { jsonText ->
            jsonParser.decodeFromString<LessonRevisionDeck>(jsonText)
        }
    }

    /**
     * Generates a calm, personalized weekly parent digest & WhatsApp cheer note grounded in live records.
     */
    suspend fun composeParentWeeklyDigest(
        student: StudentEntity,
        attendanceCount: Int,
        weakTopics: List<String>,
        lang: AppLanguage,
        orProfile: StudentOrProfile? = null,
    ): Result<ParentWeeklyDigest> {
        val langLabel = if (lang == AppLanguage.AR) "Warm Egyptian Arabic (RTL)" else "Clear Warm English"
        val studentName = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
        val wallet = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang.code)
        val dues = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang.code)
        val topics = weakTopics.takeIf { it.isNotEmpty() }?.joinToString(", ") ?: "All topics on track"
        val orLine = orProfile?.let {
            "OR Risk Tier: ${it.riskTier.key} (score ${it.riskScore}/100), Covered Sessions: ${it.coveredSessions}, Suggested Top-up: ${EgyptValidators.formatPiasters(it.recommendedInstallmentPiasters, lang.code)}"
        }.orEmpty()

        val prompt = """
            Output strictly in $langLabel without any technical jargon.
            Write a calm, trustworthy weekly digest for the parent of:
            - Student: $studentName
            - Subject Mastery: ${student.masteryPercent}%
            - Streak Days: ${student.streakDays}
            - Recorded Check-ins: $attendanceCount
            - Wallet Balance: $wallet | Pending Dues: $dues
            - Focus Topics: $topics
            - $orLine

            Produce: headline, weeklyNarrative, cheerMessage (ready to send to the student), and 1 practical homeSupportTip.
        """.trimIndent()

        return runStructuredCall(parentDigestModel, prompt) { jsonText ->
            jsonParser.decodeFromString<ParentWeeklyDigest>(jsonText)
        }
    }

    /**
     * Ultra-fast secretary WhatsApp notice composer (`gemini-3.5-flash-lite`, free tier).
     */
    suspend fun composeSecretaryNotice(
        student: StudentEntity,
        groupName: String,
        lang: AppLanguage,
        orProfile: StudentOrProfile? = null,
    ): Result<SecretaryNoticeDraft> {
        val langLabel = if (lang == AppLanguage.AR) "Polite Egyptian Arabic" else "Polite Clear English"
        val studentName = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
        val dues = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang.code)
        val wallet = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang.code)
        val suggested = orProfile?.let { EgyptValidators.formatPiasters(it.recommendedInstallmentPiasters, lang.code) }.orEmpty()
        val statusContext = when {
            student.isBlocked -> "Account temporarily paused — ask parent/student to contact reception desk gently."
            student.dueBalancePiasters > 0L -> "Gentle, dignified reminder of pending balance ($dues, optimal installment plan: $suggested) and next session in $groupName."
            else -> "Positive attendance confirmation and warm welcome for next session in $groupName (wallet balance: $wallet)."
        }

        val prompt = """
            Output strictly in $langLabel.
            Draft a short WhatsApp message (3-4 lines max) from Al-Nokhba Center reception desk regarding student "$studentName".
            Context: $statusContext
            Keep tone respectful, calm, and Egyptian center authentic. Never expose technical terms.
        """.trimIndent()

        return runStructuredCall(secretaryNoticeModel, prompt) { jsonText ->
            jsonParser.decodeFromString<SecretaryNoticeDraft>(jsonText)
        }
    }

    /**
     * Generates a 90-minute lecture pacing timeline & tiered homework for a teacher group.
     */
    suspend fun generateTeacherLessonPlan(
        group: GroupEntity,
        avgMasteryPercent: Int,
        lang: AppLanguage,
        report: SystemOperatingReport? = null,
    ): Result<TeacherLessonPlan> {
        val langLabel = if (lang == AppLanguage.AR) "Natural Egyptian Arabic (Thanaweya Amma teacher style)" else "Clear English"
        val groupTitle = if (lang == AppLanguage.AR) group.nameAr else group.nameEn
        val subject = if (lang == AppLanguage.AR) group.subjectAr else group.subjectEn
        val orContext = report?.let {
            "Hall Balance Score: ${it.groupAllocation.balanceScorePercent}%, Safety Margin: ${it.financialCertainty.marginOfSafetyPercent}%, Resource Status: ${it.resourceConflict.summaryEn}"
        }.orEmpty()

        val prompt = """
            Output strictly in $langLabel.
            Create a practical 90-minute session execution plan & tiered homework for:
            - Group: $groupTitle
            - Subject: $subject
            - Enrolled Students: ${group.enrolled}/${group.capacity}
            - Average Group Mastery: $avgMasteryPercent%
            - $orContext

            Include 4 pacingSteps with minute blocks, 2 basicHomework items, 2 challengeHomework problems, and 2 assistantChecklist items.
        """.trimIndent()

        return runStructuredCall(teacherPlanModel, prompt) { jsonText ->
            jsonParser.decodeFromString<TeacherLessonPlan>(jsonText)
        }
    }

    private suspend fun <T> runStructuredCall(
        model: com.google.firebase.ai.GenerativeModel,
        prompt: String,
        image: Bitmap? = null,
        decode: (String) -> T,
    ): Result<T> {
        return try {
            val response = withTimeout(60_000L) {
                if (image != null) {
                    model.generateContent(
                        content {
                            image(image)
                            text(prompt)
                        }
                    )
                } else {
                    model.generateContent(prompt)
                }
            }
            val jsonText = response.text ?: throw IllegalStateException("Empty structured response.")
            Result.success(decode(jsonText))
        } catch (e: TimeoutCancellationException) {
            Log.e(TOOLKIT_TAG, "Structured call timed out", e)
            Result.failure(e)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TOOLKIT_TAG, "Structured call failed", e)
            Result.failure(e)
        }
    }
}
