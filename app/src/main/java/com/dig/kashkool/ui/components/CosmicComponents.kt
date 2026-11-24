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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.DeepVoid
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.NebulaIndigo
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
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
            .background(CosmicBlack),
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawRect(
                brush = Brush.radialGradient(
                    colors = listOf(NebulaIndigo, DeepVoid, CosmicBlack),
                    center = Offset(size.width * 0.25f, size.height * 0.15f),
                    radius = size.maxDimension * 0.95f,
                )
            )
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(NeonCyan.copy(alpha = 0.14f), Color.Transparent),
                    center = Offset(size.width * 0.92f, size.height * 0.08f),
                    radius = size.minDimension * 0.55f,
                ),
                radius = size.minDimension * 0.55f,
                center = Offset(size.width * 0.92f, size.height * 0.08f),
            )
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(NebulaPurple.copy(alpha = 0.18f), Color.Transparent),
                    center = Offset(size.width * 0.08f, size.height * 0.85f),
                    radius = size.minDimension * 0.6f,
                ),
                radius = size.minDimension * 0.6f,
                center = Offset(size.width * 0.08f, size.height * 0.85f),
            )
        }
        content()
    }
}

@Composable
fun FloatingGlassCard(
    modifier: Modifier = Modifier,
    glowColor: Color = NeonCyan,
    cornerRadius: Dp = 20.dp,
    contentPadding: PaddingValues = PaddingValues(16.dp),
    onClick: (() -> Unit)? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    val shape = RoundedCornerShape(cornerRadius)
    val baseModifier = modifier
        .clip(shape)
        .background(SpaceSurface.copy(alpha = 0.82f))
        .border(
            BorderStroke(1.dp, glowColor.copy(alpha = 0.26f)),
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
            containerColor = Color.Transparent,
            disabledContainerColor = SpaceSurface.copy(alpha = 0.5f),
        ),
        contentPadding = PaddingValues(0.dp),
        modifier = modifier
            .minimumInteractiveComponentSize()
            .height(50.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = if (enabled) {
                        Brush.horizontalGradient(listOf(accentColor, ElectricBlue))
                    } else {
                        Brush.horizontalGradient(
                            listOf(Color.White.copy(alpha = 0.12f), Color.White.copy(alpha = 0.08f))
                        )
                    },
                    shape = shape,
                )
                .padding(horizontal = 18.dp),
            contentAlignment = Alignment.Center,
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
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = if (enabled) CosmicBlack else TextSecondary,
                    )
                }
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
        color = color.copy(alpha = 0.16f),
        shape = RoundedCornerShape(999.dp),
        border = BorderStroke(1.dp, color.copy(alpha = 0.4f)),
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
) {
    val hash = EgyptValidators.sha256Hex(token)
    Surface(
        color = Color.White,
        shape = RoundedCornerShape(16.dp),
        modifier = modifier,
    ) {
        Canvas(
            modifier = Modifier
                .padding(14.dp)
                .size(156.dp),
        ) {
            val grid = 21
            val cell = size.width / grid

            fun drawFinder(startX: Int, startY: Int) {
                drawRoundRect(
                    color = CosmicBlack,
                    topLeft = Offset(startX * cell, startY * cell),
                    size = Size(cell * 7, cell * 7),
                    cornerRadius = CornerRadius(4f, 4f),
                )
                drawRect(
                    color = Color.White,
                    topLeft = Offset((startX + 1) * cell, (startY + 1) * cell),
                    size = Size(cell * 5, cell * 5),
                )
                drawRect(
                    color = CosmicBlack,
                    topLeft = Offset((startX + 2) * cell, (startY + 2) * cell),
                    size = Size(cell * 3, cell * 3),
                )
            }

            drawFinder(0, 0)
            drawFinder(grid - 7, 0)
            drawFinder(0, grid - 7)

            for (row in 0 until grid) {
                for (col in 0 until grid) {
                    val inTopLeft = row < 8 && col < 8
                    val inTopRight = row < 8 && col >= grid - 8
                    val inBottomLeft = row >= grid - 8 && col < 8
                    if (inTopLeft || inTopRight || inBottomLeft) continue

                    val idx = (row * grid + col) % hash.length
                    val nibble = hash[idx].digitToIntOrNull(16) ?: 0
                    val bit = ((nibble + row + col) % 2) == 0
                    if (bit) {
                        drawRect(
                            color = CosmicBlack,
                            topLeft = Offset(col * cell, row * cell),
                            size = Size(cell * 0.92f, cell * 0.92f),
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
        initialValue = 0.25f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(900, easing = LinearEasing),
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
                    .background(Color.White.copy(alpha = alpha * 0.25f)),
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.White.copy(alpha = alpha * 0.16f)),
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
                .padding(vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = TextSecondary,
                modifier = Modifier.size(40.dp),
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
