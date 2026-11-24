package com.dig.kashkool.ui.screens

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Quiz
import androidx.compose.material.icons.filled.Security
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.ui.components.EvaluationCardMode
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.PerformanceEvaluationCard
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.CourseUnit
import com.dig.kashkool.ui.viewmodel.KashkoolUiState
import com.dig.kashkool.ui.viewmodel.QuizQuestion
import kotlin.math.roundToInt

@Composable
fun CoursesAndQuizScreen(
    state: KashkoolUiState,
    courses: List<CourseUnit>,
    questions: List<QuizQuestion>,
    onOpenLecture: (CourseUnit) -> Unit,
    onCloseLecture: () -> Unit,
    onAskStudyHelper: (String) -> Unit,
    onToggleLowDataMode: () -> Unit = {},
    onQuestionChecked: (String, Boolean) -> Unit = { _, _ -> },
    onCompleteLecture: () -> Unit = {},
    onGenerateAdaptiveQuiz: (String) -> Unit = {},
    onResetAdaptiveQuiz: () -> Unit = {},
    onEvaluateStudent: (String?) -> Unit = {},
    buildEvaluationShareText: (PerformanceEvaluationEntity) -> String = { "" },
) {
    val lang = state.language
    var showQuiz by rememberSaveable { mutableStateOf(false) }

    val activeUnit = courses.firstOrNull { it.id == state.activeLectureId }
    if (state.activeLectureTitle != null && activeUnit != null) {
        BackHandler { onCloseLecture() }
        DrmLectureView(
            unit = activeUnit,
            title = state.activeLectureTitle,
            studentLabel = state.userLabel,
            lowDataMode = state.lowDataMode,
            isCompleted = state.completedCourseIds.contains(activeUnit.id),
            lang = lang,
            onToggleLowDataMode = onToggleLowDataMode,
            onCompleteLecture = onCompleteLecture,
            onGenerateQuizFromLesson = {
                onCloseLecture()
                showQuiz = true
                onGenerateAdaptiveQuiz(state.activeLectureTitle)
            },
            onBack = onCloseLecture,
            onAskHelper = { onAskStudyHelper(state.activeLectureTitle) },
        )
        return
    }

    val activeQuizQuestions = state.adaptiveQuizQuestions ?: questions

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                FilterChip(
                    selected = !showQuiz,
                    onClick = { showQuiz = false },
                    modifier = Modifier.weight(1f).testTag("tab_courses_tree"),
                    label = { Text(AppStrings.t("courses_tab", lang)) },
                    colors = FilterChipDefaults.filterChipColors(selectedContainerColor = NeonCyan, selectedLabelColor = CosmicBlack),
                )
                FilterChip(
                    selected = showQuiz,
                    onClick = { showQuiz = true },
                    modifier = Modifier.weight(1f).testTag("tab_auto_quiz"),
                    label = { Text(AppStrings.t("quiz_tab", lang)) },
                    colors = FilterChipDefaults.filterChipColors(selectedContainerColor = SolarGold, selectedLabelColor = CosmicBlack),
                )
            }
        }

        if (!showQuiz) {
            items(courses, key = { it.id }) { unit ->
                val title = if (lang == AppLanguage.AR) unit.titleAr else unit.titleEn
                val grade = if (lang == AppLanguage.AR) unit.gradeAr else unit.gradeEn
                val isCompleted = state.completedCourseIds.contains(unit.id)
                FloatingGlassCard(
                    glowColor = if (isCompleted) EmeraldValid else ElectricBlue,
                    onClick = { onOpenLecture(unit) },
                    modifier = Modifier.fillMaxWidth().testTag("course_unit_${unit.id}"),
                ) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = if (isCompleted) Icons.Default.CheckCircle else Icons.Default.PlayCircle,
                            contentDescription = title,
                            tint = if (isCompleted) EmeraldValid else NeonCyan,
                            modifier = Modifier.size(36.dp),
                        )
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(text = grade, style = MaterialTheme.typography.labelSmall, color = ElectricBlue)
                            Text(text = title, style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                            Text(
                                text = "${unit.duration} · ${unit.dataEstimateMb} MB · ${AppStrings.t("drm_protected", lang)}",
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                        }
                        if (isCompleted) {
                            StatusPill(label = AppStrings.t("lesson_completed_badge", lang), color = EmeraldValid)
                        }
                    }
                }
            }
            item {
                PerformanceEvaluationCard(
                    evaluationState = state.evaluationState,
                    savedEvaluations = state.evaluations,
                    lang = lang,
                    mode = EvaluationCardMode.STUDENT_SELF,
                    students = state.students,
                    onEvaluateStudent = onEvaluateStudent,
                    buildShareText = buildEvaluationShareText,
                )
            }
        } else {
            item {
                val firstTitle = courses.firstOrNull()?.let { if (lang == AppLanguage.AR) it.titleAr else it.titleEn }.orEmpty()
                FloatingGlassCard(glowColor = NebulaPurple, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (state.adaptiveQuizTopic != null && state.adaptiveQuizQuestions != null) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                StatusPill(label = "${AppStrings.t("adaptive_quiz_ready", lang)} · ${state.adaptiveQuizTopic}", color = EmeraldValid)
                                OutlinedButton(onClick = onResetAdaptiveQuiz) {
                                    Text(AppStrings.t("adaptive_quiz_reset", lang), color = NeonCyan)
                                }
                            }
                        } else if (state.adaptiveQuizBusy) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp), color = NeonCyan, strokeWidth = 2.dp)
                                Text(text = AppStrings.t("adaptive_quiz_loading", lang), style = MaterialTheme.typography.bodySmall, color = NeonCyan)
                            }
                        } else {
                            NeonButton(
                                text = AppStrings.t("generate_adaptive_quiz", lang),
                                icon = Icons.Default.AutoAwesome,
                                accentColor = NebulaPurple,
                                onClick = { if (firstTitle.isNotBlank()) onGenerateAdaptiveQuiz(firstTitle) },
                                modifier = Modifier.fillMaxWidth().testTag("generate_adaptive_quiz_btn"),
                            )
                        }
                        state.adaptiveQuizError?.let { err ->
                            Text(text = "${AppStrings.t("os_ai_error_prefix", lang)} $err", style = MaterialTheme.typography.bodySmall, color = AmberDue)
                        }
                    }
                }
            }
            item {
                QuizRunnerCard(
                    questions = activeQuizQuestions,
                    lang = lang,
                    onQuestionChecked = onQuestionChecked,
                )
            }
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DrmLectureView(
    unit: CourseUnit,
    title: String,
    studentLabel: String,
    lowDataMode: Boolean,
    isCompleted: Boolean,
    lang: AppLanguage,
    onToggleLowDataMode: () -> Unit,
    onCompleteLecture: () -> Unit,
    onGenerateQuizFromLesson: () -> Unit,
    onBack: () -> Unit,
    onAskHelper: () -> Unit,
) {
    val view = LocalView.current
    DisposableEffect(view) {
        val window = view.context.findActivity()?.window
        window?.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        onDispose { window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE) }
    }

    var progress by rememberSaveable(unit.id) { mutableFloatStateOf(if (isCompleted) 1f else 0.25f) }
    val chapters = if (lang == AppLanguage.AR) {
        listOf(0.05f to "مقدمة", 0.35f to "القانون الأساسي", 0.65f to "أمثلة محلولة", 0.95f to "تمارين الامتحان")
    } else {
        listOf(0.05f to "Intro", 0.35f to "Core Rule", 0.65f to "Examples", 0.95f to "Exam Drills")
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            IconButton(onClick = onBack, modifier = Modifier.testTag("drm_back_button")) {
                Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = AppStrings.t("close", lang), tint = TextPrimary)
            }
            Text(text = title, style = MaterialTheme.typography.titleMedium, color = TextPrimary, modifier = Modifier.weight(1f))
        }

        Surface(
            color = CosmicBlack,
            shape = RoundedCornerShape(18.dp),
            border = BorderStroke(1.dp, NeonCyan.copy(alpha = 0.4f)),
            modifier = Modifier.fillMaxWidth().height(200.dp),
        ) {
            Box(modifier = Modifier.fillMaxSize().background(Color(0xFF0A1224)).padding(16.dp)) {
                Column(modifier = Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(imageVector = Icons.Default.PlayCircle, contentDescription = null, tint = NeonCyan, modifier = Modifier.size(52.dp))
                    StatusPill(label = AppStrings.t("flag_secure_active", lang), color = EmeraldValid)
                    Text(text = "${AppStrings.t("lesson_progress", lang)}: ${(progress * 100).roundToInt()}%", style = MaterialTheme.typography.labelLarge, color = NeonCyan)
                }
                Row(modifier = Modifier.align(Alignment.TopEnd), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(imageVector = Icons.Default.Security, contentDescription = null, tint = AmberDue.copy(alpha = 0.7f), modifier = Modifier.size(14.dp))
                    Text(text = studentLabel, style = MaterialTheme.typography.labelSmall, color = AmberDue.copy(alpha = 0.7f))
                }
            }
        }

        Slider(
            value = progress,
            onValueChange = { progress = it },
            colors = SliderDefaults.colors(thumbColor = NeonCyan, activeTrackColor = NeonCyan),
            modifier = Modifier.fillMaxWidth().testTag("lecture_progress_slider"),
        )

        FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            chapters.forEach { (pos, label) ->
                FilterChip(
                    selected = kotlin.math.abs(progress - pos) < 0.16f,
                    onClick = { progress = pos },
                    label = { Text(label) },
                )
            }
        }

        val summaryText = if (lang == AppLanguage.AR) unit.summaryAr else unit.summaryEn
        if (summaryText.isNotBlank()) {
            FloatingGlassCard(glowColor = ElectricBlue, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(text = AppStrings.t("lesson_summary_title", lang), style = MaterialTheme.typography.labelLarge, color = NeonCyan)
                    Text(text = summaryText, style = MaterialTheme.typography.bodySmall, color = TextPrimary)
                }
            }
        }

        FilterChip(
            selected = lowDataMode,
            onClick = onToggleLowDataMode,
            modifier = Modifier.testTag("drm_low_data_chip"),
            label = { Text(text = AppStrings.t(if (lowDataMode) "low_data_360p" else "standard_720p", lang)) },
            colors = FilterChipDefaults.filterChipColors(selectedContainerColor = EmeraldValid.copy(alpha = 0.2f), selectedLabelColor = EmeraldValid),
        )

        NeonButton(
            text = AppStrings.t(if (isCompleted) "lesson_completed_badge" else "mark_lesson_done", lang),
            icon = Icons.Default.CheckCircle,
            accentColor = EmeraldValid,
            onClick = onCompleteLecture,
            modifier = Modifier.fillMaxWidth().testTag("mark_lesson_done_button"),
        )

        OutlinedButton(
            onClick = onGenerateQuizFromLesson,
            modifier = Modifier.fillMaxWidth().testTag("lecture_generate_quiz_button"),
        ) {
            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = SolarGold, modifier = Modifier.padding(end = 6.dp))
            Text(AppStrings.t("generate_adaptive_quiz", lang), color = SolarGold)
        }

        NeonButton(
            text = AppStrings.t("ask_about_lesson", lang),
            icon = Icons.Default.AutoStories,
            accentColor = NebulaPurple,
            onClick = onAskHelper,
            modifier = Modifier.fillMaxWidth().testTag("drm_ask_helper_button"),
        )
    }
}

@Composable
private fun QuizRunnerCard(
    questions: List<QuizQuestion>,
    lang: AppLanguage,
    onQuestionChecked: (String, Boolean) -> Unit,
) {
    var index by rememberSaveable(questions.firstOrNull()?.id) { mutableIntStateOf(0) }
    var selectedOption by rememberSaveable(questions.firstOrNull()?.id, index) { mutableIntStateOf(-1) }
    var checked by rememberSaveable(questions.firstOrNull()?.id, index) { mutableStateOf(false) }
    var score by rememberSaveable(questions.firstOrNull()?.id) { mutableIntStateOf(0) }
    var finished by rememberSaveable(questions.firstOrNull()?.id) { mutableStateOf(false) }

    if (finished || questions.isEmpty()) {
        FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(imageVector = Icons.Default.Quiz, contentDescription = null, tint = SolarGold, modifier = Modifier.size(40.dp))
                Text(text = "${AppStrings.t("quiz_score", lang)}: $score / ${questions.size}", style = MaterialTheme.typography.headlineSmall, color = TextPrimary)
                NeonButton(
                    text = AppStrings.t("restart_quiz", lang),
                    accentColor = NeonCyan,
                    onClick = { index = 0; selectedOption = -1; checked = false; score = 0; finished = false },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        return
    }

    val q = questions[index.coerceIn(0, questions.lastIndex)]
    val isCorrect = selectedOption == q.correctIndex

    FloatingGlassCard(glowColor = NeonCyan, modifier = Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                StatusPill(label = if (lang == AppLanguage.AR) q.topicTagAr else q.topicTagEn, color = ElectricBlue)
                Text(text = "${index + 1} / ${questions.size}", style = MaterialTheme.typography.labelLarge, color = TextSecondary)
            }

            Text(text = if (lang == AppLanguage.AR) q.promptAr else q.promptEn, style = MaterialTheme.typography.titleMedium, color = TextPrimary)

            Surface(color = CosmicBlack.copy(alpha = 0.7f), shape = RoundedCornerShape(10.dp), modifier = Modifier.fillMaxWidth()) {
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Text(
                        text = q.formula,
                        style = MaterialTheme.typography.titleLarge.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold),
                        color = NeonCyan,
                        modifier = Modifier.padding(12.dp),
                    )
                }
            }

            q.options.forEachIndexed { idx, opt ->
                val highlight = when {
                    !checked -> if (selectedOption == idx) NeonCyan else Color.White.copy(alpha = 0.2f)
                    idx == q.correctIndex -> EmeraldValid
                    idx == selectedOption -> CrimsonBlocked
                    else -> Color.White.copy(alpha = 0.12f)
                }
                FloatingGlassCard(
                    glowColor = highlight,
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                    onClick = { if (!checked) selectedOption = idx },
                    modifier = Modifier.fillMaxWidth().testTag("quiz_option_$idx"),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        RadioButton(selected = selectedOption == idx, onClick = { if (!checked) selectedOption = idx })
                        Text(text = opt, style = MaterialTheme.typography.bodyLarge, color = TextPrimary)
                    }
                }
            }

            if (checked && !isCorrect) {
                FloatingGlassCard(glowColor = AmberDue, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(text = AppStrings.t("remedial_hint", lang), style = MaterialTheme.typography.labelMedium, color = AmberDue)
                        Text(text = if (lang == AppLanguage.AR) q.remedialAr else q.remedialEn, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                }
            }

            Spacer(modifier = Modifier.height(2.dp))
            if (!checked) {
                NeonButton(
                    text = AppStrings.t("submit_answer", lang),
                    icon = Icons.Default.CheckCircle,
                    enabled = selectedOption >= 0,
                    onClick = {
                        checked = true
                        val correct = selectedOption == q.correctIndex
                        if (correct) score++
                        onQuestionChecked(q.id, correct)
                    },
                    modifier = Modifier.fillMaxWidth().testTag("quiz_submit_button"),
                )
            } else {
                NeonButton(
                    text = AppStrings.t("next_question", lang),
                    accentColor = SolarGold,
                    onClick = { if (index + 1 < questions.size) index++ else finished = true },
                    modifier = Modifier.fillMaxWidth().testTag("quiz_next_button"),
                )
            }
        }
    }
}
