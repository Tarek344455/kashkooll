package com.dig.kashkool.ui.navigation

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.FamilyRestroom
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.PointOfSale
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.NavigationRailItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.components.CosmicBackdrop
import com.dig.kashkool.ui.screens.AttendanceDashboardScreen
import com.dig.kashkool.ui.screens.CoursesAndQuizScreen
import com.dig.kashkool.ui.screens.DashboardHomeScreen
import com.dig.kashkool.ui.screens.LoginScreen
import com.dig.kashkool.ui.screens.ParentPortalScreen
import com.dig.kashkool.ui.screens.SecretaryDeskScreen
import com.dig.kashkool.ui.screens.StudyAssistantScreen
import com.dig.kashkool.ui.screens.TeacherOpsScreen
import com.dig.kashkool.ui.screens.WalletAndPaymentsScreen
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState
import com.dig.kashkool.ui.viewmodel.KashkoolViewModel
import kotlinx.serialization.Serializable

@Serializable
data object LoginRoute

@Serializable
data object WorkspaceRoute

private data class WorkspaceTab(
    val id: String,
    val labelKey: String,
    val icon: ImageVector,
)

@Composable
fun KashkoolApp(
    viewModel: KashkoolViewModel = viewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val navController = rememberNavController()
    val layoutDirection = if (state.language.isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr

    LaunchedEffect(state.signedIn) {
        val currentRoute = navController.currentDestination?.route
        if (state.signedIn && currentRoute?.contains("WorkspaceRoute") != true) {
            navController.navigate(WorkspaceRoute) {
                popUpTo(LoginRoute) { inclusive = true }
            }
        } else if (!state.signedIn && currentRoute?.contains("LoginRoute") != true) {
            navController.navigate(LoginRoute) {
                popUpTo(0) { inclusive = true }
            }
        }
    }

    CompositionLocalProvider(LocalLayoutDirection provides layoutDirection) {
        NavHost(
            navController = navController,
            startDestination = LoginRoute,
        ) {
            composable<LoginRoute> {
                LoginScreen(
                    state = state,
                    onToggleLanguage = viewModel::toggleLanguage,
                    onSelectMode = viewModel::setAuthMode,
                    onRequestOtp = viewModel::requestOtp,
                    onVerifyOtp = viewModel::verifyOtp,
                    onActivateQr = viewModel::activateWithQr,
                    onEnterOfflineRole = viewModel::enterOfflineWorkspace,
                )
            }
            composable<WorkspaceRoute> {
                WorkspaceShell(
                    state = state,
                    viewModel = viewModel,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun WorkspaceShell(
    state: KashkoolUiState,
    viewModel: KashkoolViewModel,
) {
    val lang = state.language
    val tabs = remember(state.activeRole) { tabsForRole(state.activeRole) }
    var activeTabId by rememberSaveable(state.activeRole) { mutableStateOf("home") }
    if (activeTabId != "analytics" && tabs.none { it.id == activeTabId }) {
        activeTabId = "home"
    }

    if (activeTabId != "home") {
        BackHandler { activeTabId = "home" }
    }

    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(state.snackbarMessage) {
        val msg = state.snackbarMessage
        if (!msg.isNullOrBlank()) {
            snackbarHostState.showSnackbar(msg)
            viewModel.clearSnackbar()
        }
    }

    CosmicBackdrop {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val useRail = maxWidth >= 600.dp

            Scaffold(
                containerColor = Color.Transparent,
                contentWindowInsets = WindowInsets.safeDrawing,
                snackbarHost = { SnackbarHost(snackbarHostState) },
                topBar = {
                    TopAppBar(
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = SpaceSurface.copy(alpha = 0.94f),
                            titleContentColor = TextPrimary,
                        ),
                        title = {
                            Text(
                                text = AppStrings.t("app_title", lang),
                                style = MaterialTheme.typography.titleLarge,
                            )
                        },
                        actions = {
                            IconButton(
                                onClick = viewModel::toggleLanguage,
                                modifier = Modifier.testTag("shell_language_button"),
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Translate,
                                    contentDescription = "Language",
                                    tint = NeonCyan,
                                )
                            }
                            IconButton(
                                onClick = viewModel::signOut,
                                modifier = Modifier.testTag("shell_signout_button"),
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.Logout,
                                    contentDescription = AppStrings.t("sign_out", lang),
                                    tint = TextSecondary,
                                )
                            }
                        },
                    )
                },
                bottomBar = {
                    if (!useRail) {
                        NavigationBar(
                            containerColor = SpaceSurface.copy(alpha = 0.96f),
                        ) {
                            tabs.forEach { tab ->
                                val selected = activeTabId == tab.id
                                NavigationBarItem(
                                    selected = selected,
                                    onClick = { activeTabId = tab.id },
                                    modifier = Modifier.testTag("nav_tab_${tab.id}"),
                                    icon = {
                                        Icon(
                                            imageVector = tab.icon,
                                            contentDescription = AppStrings.t(tab.labelKey, lang),
                                        )
                                    },
                                    label = {
                                        Text(
                                            text = AppStrings.t(tab.labelKey, lang),
                                            maxLines = 1,
                                        )
                                    },
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = NeonCyan,
                                        selectedTextColor = NeonCyan,
                                        indicatorColor = NeonCyan.copy(alpha = 0.14f),
                                        unselectedIconColor = TextSecondary,
                                        unselectedTextColor = TextSecondary,
                                    ),
                                )
                            }
                        }
                    }
                },
            ) { innerPadding ->
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding),
                ) {
                    if (useRail) {
                        NavigationRail(
                            containerColor = SpaceSurface.copy(alpha = 0.94f),
                        ) {
                            tabs.forEach { tab ->
                                val selected = activeTabId == tab.id
                                NavigationRailItem(
                                    selected = selected,
                                    onClick = { activeTabId = tab.id },
                                    icon = {
                                        Icon(
                                            imageVector = tab.icon,
                                            contentDescription = AppStrings.t(tab.labelKey, lang),
                                        )
                                    },
                                    label = {
                                        Text(AppStrings.t(tab.labelKey, lang))
                                    },
                                    colors = NavigationRailItemDefaults.colors(
                                        selectedIconColor = NeonCyan,
                                        selectedTextColor = NeonCyan,
                                        indicatorColor = NeonCyan.copy(alpha = 0.14f),
                                        unselectedIconColor = TextSecondary,
                                        unselectedTextColor = TextSecondary,
                                    ),
                                )
                            }
                        }
                    }

                    Box(modifier = Modifier.weight(1f).fillMaxSize()) {
                        when (activeTabId) {
                            "home" -> DashboardHomeScreen(
                                state = state,
                                onNavigateTab = { target -> activeTabId = target },
                                onToggleStreakShield = viewModel::toggleStreakShield,
                                onReviewRescueItem = { topic ->
                                    viewModel.askStudyAssistant(
                                        prompt = if (lang.isRtl) "اشرح لي نقطة $topic بخطة سريعة" else "Review $topic step by step",
                                        subject = topic,
                                    )
                                    activeTabId = "assistant"
                                },
                                onCompleteRescueItem = viewModel::completeRescueItem,
                                onQrCodeCopied = viewModel::notifyQrCopied,
                            )
                            "desk" -> SecretaryDeskScreen(
                                state = state,
                                onCheckInStudent = viewModel::checkInStudent,
                                onRecordCashEntry = viewModel::recordCashDeskEntry,
                                buildThermalReceipt = viewModel::buildThermalReceipt,
                                onGenerateQrCode = viewModel::generateQrForStudent,
                                onDismissGeneratedQr = viewModel::dismissGeneratedQr,
                                onToggleRushMode = viewModel::toggleRushMode,
                                onDiscreetAllow = viewModel::discreetAllowWithParentNotice,
                                onAddWalkInStudent = viewModel::addWalkInStudent,
                                onToggleBlockStudent = viewModel::toggleStudentBlocked,
                                onComposeNotice = viewModel::composeSecretaryNotice,
                                onDismissNotice = viewModel::dismissSecretaryNotice,
                                onScanQrPayload = viewModel::scanQrForAttendance,
                            )
                            "analytics" -> AttendanceDashboardScreen(
                                state = state,
                                onSelectWindow = viewModel::setAttendanceWindow,
                                onSelectChartMode = viewModel::setAttendanceChartMode,
                                onSelectGroupFilter = viewModel::setAttendanceGroupFilter,
                            )
                            "teacher" -> TeacherOpsScreen(
                                state = state,
                                onCreateGroup = viewModel::createGroup,
                                onExecuteSettlement = viewModel::executeDailySettlement,
                                onApproveSubmission = viewModel::approveSubmission,
                                onRejectSubmission = viewModel::rejectSubmission,
                                onUpgradeCenterPlan = viewModel::submitCenterPlanUpgrade,
                                onExecuteOrRebalance = viewModel::executeOrSeatRebalance,
                                onUpdateSettlementControls = viewModel::updateSettlementControls,
                                onAddResource = viewModel::addResource,
                                onCycleResourceStatus = viewModel::cycleResourceStatus,
                                onAddChannel = viewModel::addPaymentChannel,
                                onToggleChannelActive = viewModel::toggleChannelActive,
                                onEvaluateTeacher = viewModel::evaluateTeacherPerformance,
                                onEvaluateStudent = viewModel::evaluateStudentPerformance,
                                buildEvaluationShareText = { eval -> viewModel.buildEvaluationShareText(eval, lang) },
                                onGenerateLessonPlan = viewModel::generateTeacherLessonPlan,
                                onOpenAttendanceDashboard = { activeTabId = "analytics" },
                            )
                            "courses" -> CoursesAndQuizScreen(
                                state = state,
                                courses = viewModel.courses,
                                questions = viewModel.quizQuestions,
                                onOpenLecture = { unit -> viewModel.openLecture(unit, lang) },
                                onCloseLecture = viewModel::closeLecture,
                                onAskStudyHelper = { lectureTitle ->
                                    viewModel.closeLecture()
                                    viewModel.askStudyAssistant(
                                        prompt = if (lang.isRtl) "اشرح لي أهم نقاط: $lectureTitle" else "Summarize key points of: $lectureTitle",
                                        subject = lectureTitle,
                                    )
                                    activeTabId = "assistant"
                                },
                                onToggleLowDataMode = viewModel::toggleLowDataMode,
                                onQuestionChecked = viewModel::recordQuizOutcome,
                                onCompleteLecture = viewModel::markActiveLectureCompleted,
                                onGenerateAdaptiveQuiz = viewModel::generateAdaptiveQuiz,
                                onResetAdaptiveQuiz = viewModel::resetAdaptiveQuiz,
                                onEvaluateStudent = viewModel::evaluateStudentPerformance,
                                buildEvaluationShareText = { eval -> viewModel.buildEvaluationShareText(eval, lang) },
                                onGenerateRevisionDeck = viewModel::generateLessonRevisionDeck,
                            )
                            "wallet" -> WalletAndPaymentsScreen(
                                state = state,
                                onSubmitReceipt = viewModel::submitPaymentReceipt,
                                onVoidLedgerEntry = viewModel::voidLedgerEntry,
                                onCompressReceipt = viewModel::compressAndAttachReceipt,
                                onClearCompressedReceipt = viewModel::clearCompressedReceipt,
                                onScanReceipt = viewModel::scanAttachedReceipt,
                            )
                            "assistant" -> StudyAssistantScreen(
                                state = state,
                                onSendPrompt = { prompt, photoUri ->
                                    viewModel.askStudyAssistant(prompt = prompt, photoUri = photoUri)
                                },
                            )
                            "parent" -> ParentPortalScreen(
                                state = state,
                                onTopUpClick = { activeTabId = "wallet" },
                                onReassureNow = viewModel::triggerParentReassurance,
                                buildCheerMessage = viewModel::buildEncouragementMessage,
                                buildParentReportText = viewModel::buildParentReportShareText,
                                onCheerCopied = viewModel::notifyMessageCopied,
                                onEvaluateChild = viewModel::evaluateStudentPerformance,
                                buildEvaluationShareText = { eval -> viewModel.buildEvaluationShareText(eval, lang) },
                                onRefreshDigest = viewModel::refreshParentWeeklyDigest,
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun tabsForRole(role: UserRole): List<WorkspaceTab> {
    return when (role) {
        UserRole.SECRETARY -> listOf(
            WorkspaceTab("home", "nav_home", Icons.Default.Home),
            WorkspaceTab("desk", "nav_desk", Icons.Default.PointOfSale),
            WorkspaceTab("analytics", "nav_analytics", Icons.Default.Insights),
            WorkspaceTab("teacher", "nav_teacher", Icons.Default.Dashboard),
            WorkspaceTab("wallet", "nav_wallet", Icons.Default.AccountBalanceWallet),
        )
        UserRole.TEACHER -> listOf(
            WorkspaceTab("home", "nav_home", Icons.Default.Home),
            WorkspaceTab("teacher", "nav_teacher", Icons.Default.Dashboard),
            WorkspaceTab("courses", "nav_courses", Icons.Default.School),
            WorkspaceTab("assistant", "nav_assistant", Icons.Default.AutoStories),
            WorkspaceTab("desk", "nav_desk", Icons.Default.PointOfSale),
        )
        UserRole.PARENT -> listOf(
            WorkspaceTab("home", "nav_home", Icons.Default.Home),
            WorkspaceTab("parent", "nav_parent", Icons.Default.FamilyRestroom),
            WorkspaceTab("wallet", "nav_wallet", Icons.Default.AccountBalanceWallet),
            WorkspaceTab("courses", "nav_courses", Icons.Default.School),
        )
        UserRole.STUDENT -> listOf(
            WorkspaceTab("home", "nav_home", Icons.Default.Home),
            WorkspaceTab("courses", "nav_courses", Icons.Default.School),
            WorkspaceTab("assistant", "nav_assistant", Icons.Default.AutoStories),
            WorkspaceTab("wallet", "nav_wallet", Icons.Default.AccountBalanceWallet),
        )
    }
}
