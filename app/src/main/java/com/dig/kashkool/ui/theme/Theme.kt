package com.dig.kashkool.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp

private val CosmicDarkColorScheme = darkColorScheme(
    primary = NeonCyan,
    onPrimary = CosmicBlack,
    primaryContainer = NebulaIndigo,
    onPrimaryContainer = TextPrimary,
    secondary = ElectricBlue,
    onSecondary = CosmicBlack,
    secondaryContainer = SpaceSurfaceVariant,
    onSecondaryContainer = TextPrimary,
    tertiary = SolarGold,
    onTertiary = CosmicBlack,
    background = DeepVoid,
    onBackground = TextPrimary,
    surface = SpaceSurface,
    onSurface = TextPrimary,
    surfaceVariant = SpaceSurfaceVariant,
    onSurfaceVariant = TextSecondary,
    outline = SpaceBorder,
    error = CrimsonBlocked,
    onError = CosmicBlack,
)

private val KashkoolShapes = Shapes(
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(20.dp),
)

@Composable
fun KashkoolTheme(
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = CosmicDarkColorScheme,
        typography = Typography,
        shapes = KashkoolShapes,
        content = content,
    )
}