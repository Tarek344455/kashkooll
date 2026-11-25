package com.dig.kashkool.ui.screens

import android.net.Uri
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState
import java.util.Locale

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun StudyAssistantScreen(
    state: KashkoolUiState,
    onSendPrompt: (String, Uri?) -> Unit,
) {
    val lang = state.language
    val context = LocalContext.current
    var promptText by rememberSaveable { mutableStateOf("") }
    var pendingPhotoUriString by rememberSaveable { mutableStateOf<String?>(null) }
    var speakingIndex by remember { mutableIntStateOf(-1) }
    var ttsReady by remember { mutableStateOf(false) }

    val tts = remember(context) {
        var instance: TextToSpeech? = null
        instance = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val targetLocale = if (lang == AppLanguage.AR) {
                    Locale.forLanguageTag("ar-EG")
                } else {
                    Locale.US
                }
                val result = instance?.setLanguage(targetLocale)
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    instance?.setLanguage(Locale.getDefault())
                }
                ttsReady = true
            }
        }
        instance.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) { speakingIndex = -1 }
            @Suppress("OVERRIDE_DEPRECATION")
            override fun onError(utteranceId: String?) { speakingIndex = -1 }
            override fun onError(utteranceId: String?, errorCode: Int) { speakingIndex = -1 }
        })
        instance
    }

    DisposableEffect(tts) {
        onDispose {
            tts.stop()
            tts.shutdown()
        }
    }

    val photoPicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            pendingPhotoUriString = uri.toString()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
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
            itemsIndexed(state.assistantMessages) { index, msg ->
                val isSpeakingThis = speakingIndex == index
                FloatingGlassCard(
                    glowColor = if (msg.fromUser) NeonCyan else ElectricBlue,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (!msg.attachedPhotoUri.isNullOrBlank()) {
                            AsyncImage(
                                model = msg.attachedPhotoUri,
                                contentDescription = AppStrings.t("assistant_photo_attached", lang),
                                contentScale = ContentScale.Crop,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .heightIn(max = 180.dp)
                                    .clip(RoundedCornerShape(12.dp)),
                            )
                        }
                        Text(
                            text = msg.text,
                            style = MaterialTheme.typography.bodyMedium,
                            color = TextPrimary,
                        )
                        if (!msg.fromUser && msg.text.isNotBlank() && ttsReady) {
                            OutlinedButton(
                                onClick = {
                                    if (isSpeakingThis) {
                                        tts.stop()
                                        speakingIndex = -1
                                    } else {
                                        val locale = if (lang == AppLanguage.AR) Locale.forLanguageTag("ar-EG") else Locale.US
                                        val res = tts.setLanguage(locale)
                                        if (res == TextToSpeech.LANG_MISSING_DATA || res == TextToSpeech.LANG_NOT_SUPPORTED) {
                                            tts.setLanguage(Locale.getDefault())
                                        }
                                        speakingIndex = index
                                        tts.speak(msg.text, TextToSpeech.QUEUE_FLUSH, null, "msg_$index")
                                    }
                                },
                                modifier = Modifier.testTag("assistant_tts_button_$index"),
                            ) {
                                Icon(
                                    imageVector = if (isSpeakingThis) Icons.Default.Stop else Icons.AutoMirrored.Filled.VolumeUp,
                                    contentDescription = null,
                                    tint = if (isSpeakingThis) AmberDue else NeonCyan,
                                    modifier = Modifier.size(16.dp).padding(end = 4.dp),
                                )
                                Text(
                                    text = AppStrings.t(
                                        if (isSpeakingThis) "assistant_stop_reading" else "assistant_read_aloud",
                                        lang,
                                    ),
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (isSpeakingThis) AmberDue else NeonCyan,
                                )
                            }
                        }
                        if (msg.suggestions.isNotEmpty()) {
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                msg.suggestions.forEach { s ->
                                    AssistChip(
                                        onClick = { onSendPrompt(s, null) },
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
                        glowColor = AmberDue,
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

        if (pendingPhotoUriString != null) {
            FloatingGlassCard(
                glowColor = EmeraldValid,
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    AsyncImage(
                        model = pendingPhotoUriString,
                        contentDescription = AppStrings.t("assistant_photo_attached", lang),
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(8.dp)),
                    )
                    Text(
                        text = AppStrings.t("assistant_photo_attached", lang),
                        style = MaterialTheme.typography.bodySmall,
                        color = EmeraldValid,
                        modifier = Modifier.weight(1f),
                    )
                    IconButton(onClick = { pendingPhotoUriString = null }) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = AppStrings.t("close", lang),
                            tint = TextSecondary,
                        )
                    }
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = {
                    photoPicker.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                },
                enabled = !state.assistantBusy,
                modifier = Modifier.testTag("assistant_attach_photo_button"),
            ) {
                Icon(
                    imageVector = Icons.Default.AddAPhoto,
                    contentDescription = AppStrings.t("assistant_attach_photo", lang),
                    tint = if (pendingPhotoUriString != null) EmeraldValid else NeonCyan,
                )
            }
            OutlinedTextField(
                value = promptText,
                onValueChange = { promptText = it },
                placeholder = {
                    Text(
                        AppStrings.t(
                            if (pendingPhotoUriString != null) "assistant_photo_hint" else "assistant_hint",
                            lang,
                        )
                    )
                },
                singleLine = true,
                modifier = Modifier
                    .weight(1f)
                    .testTag("assistant_prompt_input"),
            )
            IconButton(
                onClick = {
                    val toSend = promptText
                    val photoUri = pendingPhotoUriString?.let(Uri::parse)
                    promptText = ""
                    pendingPhotoUriString = null
                    onSendPrompt(toSend, photoUri)
                },
                enabled = (promptText.isNotBlank() || pendingPhotoUriString != null) && !state.assistantBusy,
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
