package com.dig.kashkool.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.components.CosmicBackdrop
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.AuthMode
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun LoginScreen(
    state: KashkoolUiState,
    onToggleLanguage: () -> Unit,
    onSelectMode: (AuthMode) -> Unit,
    onRequestOtp: (String) -> Unit,
    onVerifyOtp: (String) -> Unit,
    onActivateQr: (String) -> Unit,
    onEnterOfflineRole: (UserRole) -> Unit,
) {
    val lang = state.language
    var inputText by rememberSaveable(state.auth.mode) { mutableStateOf("") }
    var otpText by rememberSaveable { mutableStateOf("") }

    CosmicBackdrop {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        imageVector = Icons.Default.School,
                        contentDescription = AppStrings.t("app_title", lang),
                        tint = NeonCyan,
                        modifier = Modifier.size(28.dp),
                    )
                    Text(
                        text = AppStrings.t("app_title", lang),
                        style = MaterialTheme.typography.titleLarge,
                        color = TextPrimary,
                    )
                }

                FilterChip(
                    selected = true,
                    onClick = onToggleLanguage,
                    modifier = Modifier.testTag("language_toggle_button"),
                    label = {
                        Text(
                            text = if (lang == AppLanguage.AR) "English" else "العربية",
                            style = MaterialTheme.typography.labelMedium,
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = NeonCyan.copy(alpha = 0.16f),
                        selectedLabelColor = NeonCyan,
                    ),
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            Column(
                modifier = Modifier.widthIn(max = 460.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = AppStrings.t("welcome", lang),
                    style = MaterialTheme.typography.headlineMedium,
                    color = TextPrimary,
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = AppStrings.t("subtitle_cosmic", lang),
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextSecondary,
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(14.dp))

                Surface(
                    color = (if (state.backendConfigured) EmeraldValid else AmberDue).copy(alpha = 0.12f),
                    shape = RoundedCornerShape(12.dp),
                    border = BorderStroke(
                        1.dp,
                        (if (state.backendConfigured) EmeraldValid else AmberDue).copy(alpha = 0.35f),
                    ),
                ) {
                    Text(
                        text = AppStrings.t(
                            if (state.backendConfigured) "backend_ready" else "backend_offline",
                            lang,
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (state.backendConfigured) EmeraldValid else AmberDue,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Surface(
                    color = NeonCyan.copy(alpha = 0.10f),
                    shape = RoundedCornerShape(999.dp),
                    border = BorderStroke(1.dp, NeonCyan.copy(alpha = 0.3f)),
                ) {
                    Text(
                        text = AppStrings.t("zero_cost_badge", lang),
                        style = MaterialTheme.typography.labelSmall,
                        color = NeonCyan,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 5.dp),
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                FloatingGlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            AuthMode.entries.forEach { mode ->
                                val selected = state.auth.mode == mode
                                val key = when (mode) {
                                    AuthMode.PHONE -> "mode_phone"
                                    AuthMode.EMAIL -> "mode_email"
                                    AuthMode.QR -> "mode_qr"
                                }
                                FilterChip(
                                    selected = selected,
                                    onClick = { onSelectMode(mode) },
                                    modifier = Modifier.weight(1f),
                                    label = {
                                        Text(
                                            text = AppStrings.t(key, lang),
                                            maxLines = 1,
                                            style = MaterialTheme.typography.labelMedium,
                                        )
                                    },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = NeonCyan,
                                        selectedLabelColor = CosmicBlack,
                                    ),
                                )
                            }
                        }

                        if (!state.auth.awaitingOtp) {
                            val labelKey = when (state.auth.mode) {
                                AuthMode.PHONE -> "phone_label"
                                AuthMode.EMAIL -> "email_label"
                                AuthMode.QR -> "qr_code_label"
                            }
                            val hintKey = when (state.auth.mode) {
                                AuthMode.PHONE -> "phone_hint"
                                AuthMode.EMAIL -> "email_hint"
                                AuthMode.QR -> "qr_code_hint"
                            }
                            val icon = when (state.auth.mode) {
                                AuthMode.PHONE -> Icons.Default.Phone
                                AuthMode.EMAIL -> Icons.Default.Email
                                AuthMode.QR -> Icons.Default.QrCode2
                            }
                            val kbType = when (state.auth.mode) {
                                AuthMode.PHONE -> KeyboardType.Phone
                                AuthMode.EMAIL -> KeyboardType.Email
                                AuthMode.QR -> KeyboardType.Text
                            }

                            OutlinedTextField(
                                value = inputText,
                                onValueChange = { inputText = it },
                                label = { Text(AppStrings.t(labelKey, lang)) },
                                placeholder = { Text(AppStrings.t(hintKey, lang)) },
                                leadingIcon = { Icon(icon, contentDescription = null, tint = NeonCyan) },
                                keyboardOptions = KeyboardOptions(keyboardType = kbType),
                                singleLine = true,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("auth_identifier_input"),
                            )

                            NeonButton(
                                text = AppStrings.t(
                                    if (state.auth.mode == AuthMode.QR) "activate_qr" else "send_code",
                                    lang,
                                ),
                                loading = state.auth.busy,
                                enabled = state.auth.mode == AuthMode.QR || state.backendConfigured,
                                onClick = {
                                    if (state.auth.mode == AuthMode.QR) {
                                        onActivateQr(inputText)
                                    } else {
                                        onRequestOtp(inputText)
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("auth_submit_button"),
                            )
                        } else {
                            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                                Text(
                                    text = state.auth.identifier,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = NeonCyan,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.fillMaxWidth(),
                                )
                            }
                            OutlinedTextField(
                                value = otpText,
                                onValueChange = { if (it.length <= 6) otpText = it },
                                label = { Text(AppStrings.t("otp_label", lang)) },
                                leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = NeonCyan) },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("auth_otp_input"),
                            )
                            NeonButton(
                                text = AppStrings.t("verify_code", lang),
                                loading = state.auth.busy,
                                onClick = { onVerifyOtp(otpText) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("auth_verify_button"),
                            )
                            TextButton(
                                onClick = { onSelectMode(state.auth.mode) },
                                modifier = Modifier.align(Alignment.CenterHorizontally),
                            ) {
                                Text(AppStrings.t("change_input", lang))
                            }
                        }

                        if (!state.auth.errorMessage.isNullOrBlank()) {
                            Text(
                                text = state.auth.errorMessage,
                                color = CrimsonBlocked,
                                style = MaterialTheme.typography.bodySmall,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.fillMaxWidth(),
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                FloatingGlassCard(
                    glowColor = SolarGold,
                    contentPadding = PaddingValues(16.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            text = AppStrings.t("offline_roles_title", lang),
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = SolarGold,
                        )
                        FlowRow(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            listOf(
                                UserRole.STUDENT to "role_student",
                                UserRole.SECRETARY to "role_secretary",
                                UserRole.TEACHER to "role_teacher",
                                UserRole.PARENT to "role_parent",
                            ).forEach { (role, key) ->
                                OutlinedButton(
                                    onClick = { onEnterOfflineRole(role) },
                                    border = BorderStroke(1.dp, NeonCyan.copy(alpha = 0.45f)),
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.testTag("offline_role_${role.key}"),
                                ) {
                                    Text(
                                        text = AppStrings.t(key, lang),
                                        color = TextPrimary,
                                        style = MaterialTheme.typography.labelLarge,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
