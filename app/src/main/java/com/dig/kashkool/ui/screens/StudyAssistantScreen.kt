package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun StudyAssistantScreen(
    state: KashkoolUiState,
    onSendPrompt: (String) -> Unit,
) {
    val lang = state.language
    var promptText by rememberSaveable { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        FloatingGlassCard(
            glowColor = NebulaPurple,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(
                    imageVector = Icons.Default.AutoStories,
                    contentDescription = AppStrings.t("assistant_title", lang),
                    tint = NeonCyan,
                    modifier = Modifier.size(28.dp),
                )
                Column {
                    Text(
                        text = AppStrings.t("assistant_title", lang),
                        style = MaterialTheme.typography.titleMedium,
                        color = TextPrimary,
                    )
                    Text(
                        text = AppStrings.t("assistant_subtitle", lang),
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                    )
                }
            }
        }

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentPadding = PaddingValues(vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            items(state.assistantMessages) { msg ->
                FloatingGlassCard(
                    glowColor = if (msg.fromUser) NeonCyan else ElectricBlue,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = msg.text,
                            style = MaterialTheme.typography.bodyMedium,
                            color = TextPrimary,
                        )
                        if (msg.suggestions.isNotEmpty()) {
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                msg.suggestions.forEach { s ->
                                    AssistChip(
                                        onClick = { onSendPrompt(s) },
                                        label = { Text(s, style = MaterialTheme.typography.bodySmall) },
                                    )
                                }
                            }
                        }
                    }
                }
            }

            if (state.assistantBusy) {
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = NeonCyan,
                            strokeWidth = 2.dp,
                        )
                    }
                }
            }

            if (!state.assistantError.isNullOrBlank()) {
                item {
                    FloatingGlassCard(
                        glowColor = com.dig.kashkool.ui.theme.AmberDue,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(
                            text = "${AppStrings.t("os_ai_error_prefix", lang)} ${state.assistantError}",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextPrimary,
                        )
                    }
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = promptText,
                onValueChange = { promptText = it },
                placeholder = { Text(AppStrings.t("assistant_hint", lang)) },
                singleLine = true,
                modifier = Modifier
                    .weight(1f)
                    .testTag("assistant_prompt_input"),
            )
            IconButton(
                onClick = {
                    val toSend = promptText
                    promptText = ""
                    onSendPrompt(toSend)
                },
                enabled = promptText.isNotBlank() && !state.assistantBusy,
                modifier = Modifier.testTag("assistant_send_button"),
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Send,
                    contentDescription = AppStrings.t("send", lang),
                    tint = NeonCyan,
                )
            }
        }
    }
}
