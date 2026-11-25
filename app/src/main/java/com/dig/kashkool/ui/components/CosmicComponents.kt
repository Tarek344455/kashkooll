package com.dig.kashkool.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.utils.QrMatrixGenerator
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.DeepVoid
import com.dig.kashkool.ui.theme.NebulaIndigo
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SpaceBorder
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextSecondary

@Composable
fun CosmicBackdrop(
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(DeepVoid, CosmicBlack),
                )
            ),
    ) {
        // Very subtle ambient depth without harsh neon glow spots
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(NebulaIndigo.copy(alpha = 0.45f), Color.Transparent),
                    center = Offset(size.width * 0.5f, 0f),
                    radius = size.maxDimension * 0.65f,
                ),
                radius = size.maxDimension * 0.65f,
                center = Offset(size.width * 0.5f, 0f),
            )
        }
        content()
    }
}

@Composable
fun FloatingGlassCard(
    modifier: Modifier = Modifier,
    glowColor: Color = NeonCyan,
    cornerRadius: Dp = 18.dp,
    contentPadding: PaddingValues = PaddingValues(18.dp),
    onClick: (() -> Unit)? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    val shape = RoundedCornerShape(cornerRadius)
    val subtleBorder = if (glowColor == NeonCyan) {
        SpaceBorder
    } else {
        glowColor.copy(alpha = 0.16f)
    }
    val baseModifier = modifier
        .clip(shape)
        .background(SpaceSurface.copy(alpha = 0.94f))
        .border(
            BorderStroke(1.dp, subtleBorder),
            shape = shape,
        )
        .let {
            if (onClick != null) {
                it.minimumInteractiveComponentSize().clickable(onClick = onClick)
            } else {
                it
            }
        }
        .padding(contentPadding)

    Box(modifier = baseModifier, content = content)
}

@Composable
fun NeonButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    loading: Boolean = false,
    accentColor: Color = NeonCyan,
) {
    val shape = RoundedCornerShape(14.dp)
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        shape = shape,
        colors = ButtonDefaults.buttonColors(
            containerColor = if (enabled) accentColor else SpaceSurface.copy(alpha = 0.6f),
            disabledContainerColor = Color.White.copy(alpha = 0.08f),
        ),
        contentPadding = PaddingValues(horizontal = 18.dp),
        modifier = modifier
            .minimumInteractiveComponentSize()
            .height(48.dp),
    ) {
        if (loading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                strokeWidth = 2.dp,
                color = CosmicBlack,
            )
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (icon != null) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = if (enabled) CosmicBlack else TextSecondary,
                        modifier = Modifier.size(18.dp),
                    )
                }
                Text(
                    text = text,
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = if (enabled) CosmicBlack else TextSecondary,
                    maxLines = 1,
                )
            }
        }
    }
}

@Composable
fun StatusPill(
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier,
        color = color.copy(alpha = 0.12f),
        shape = RoundedCornerShape(999.dp),
        border = BorderStroke(1.dp, color.copy(alpha = 0.24f)),
    ) {
        Text(
            text = label,
            color = color,
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
        )
    }
}

@Composable
fun DynamicQrCanvas(
    token: String,
    modifier: Modifier = Modifier,
    sizeDp: Dp = 172.dp,
) {
    val qrMatrix = remember(token) { QrMatrixGenerator.encode(token) }
    Surface(
        color = Color.White,
        shape = RoundedCornerShape(16.dp),
        modifier = modifier,
    ) {
        Canvas(
            modifier = Modifier
                .padding(14.dp)
                .size(sizeDp),
        ) {
            val grid = qrMatrix.size.coerceAtLeast(1)
            val cell = size.width / grid
            val moduleSize = Size(cell + 0.35f, cell + 0.35f)
            for (row in 0 until grid) {
                for (col in 0 until grid) {
                    if (qrMatrix.isDark(col, row)) {
                        drawRect(
                            color = Color.Black,
                            topLeft = Offset(col * cell, row * cell),
                            size = moduleSize,
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ShimmerSkeletonCard(modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val alpha by transition.animateFloat(
        initialValue = 0.2f,
        targetValue = 0.45f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "shimmerAlpha",
    )
    FloatingGlassCard(modifier = modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.55f)
                    .height(16.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.White.copy(alpha = alpha * 0.22f)),
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.White.copy(alpha = alpha * 0.14f)),
            )
        }
    }
}

@Composable
fun EmptyStateCard(
    icon: ImageVector,
    message: String,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    FloatingGlassCard(modifier = modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = TextSecondary,
                modifier = Modifier.size(38.dp),
            )
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                textAlign = TextAlign.Center,
            )
            if (actionLabel != null && onAction != null) {
                Spacer(modifier = Modifier.height(2.dp))
                NeonButton(text = actionLabel, onClick = onAction)
            }
        }
    }
}
