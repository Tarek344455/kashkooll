package com.dig.kashkool.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.analytics.DailyAttendancePoint
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.TextSecondary
import kotlin.math.roundToInt

@Composable
fun AttendanceTrendAreaChart(
    points: List<DailyAttendancePoint>,
    selectedIndex: Int?,
    onSelectIndex: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (points.isEmpty()) return
    val maxY = (points.maxOfOrNull { it.totalCount } ?: 0).coerceAtLeast(4)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .testTag("attendance_area_chart"),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(210.dp),
        ) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(points) {
                        detectTapGestures { offset ->
                            if (points.isNotEmpty() && size.width > 0) {
                                val step = if (points.size == 1) 0f else size.width.toFloat() / (points.size - 1)
                                val idx = if (step <= 0f) 0 else (offset.x / step).roundToInt().coerceIn(0, points.lastIndex)
                                onSelectIndex(idx)
                            }
                        }
                    },
            ) {
                val leftPad = 28.dp.toPx()
                val rightPad = 14.dp.toPx()
                val topPad = 14.dp.toPx()
                val bottomPad = 12.dp.toPx()
                val chartW = (size.width - leftPad - rightPad).coerceAtLeast(1f)
                val chartH = (size.height - topPad - bottomPad).coerceAtLeast(1f)
                val dash = PathEffect.dashPathEffect(floatArrayOf(8f, 8f), 0f)

                // Horizontal gridlines (4 levels)
                for (i in 0..4) {
                    val y = topPad + chartH * (i / 4f)
                    drawLine(
                        color = Color.White.copy(alpha = 0.12f),
                        start = Offset(leftPad, y),
                        end = Offset(leftPad + chartW, y),
                        strokeWidth = 1.dp.toPx(),
                        pathEffect = dash,
                    )
                }

                val stepX = if (points.size <= 1) 0f else chartW / (points.size - 1)

                fun pointOffset(index: Int, value: Int): Offset {
                    val x = if (points.size == 1) leftPad + chartW / 2f else leftPad + index * stepX
                    val ratio = (value.toFloat() / maxY.toFloat()).coerceIn(0f, 1f)
                    val y = topPad + chartH * (1f - ratio)
                    return Offset(x, y)
                }

                val totalOffsets = points.mapIndexed { idx, p -> pointOffset(idx, p.totalCount) }
                val validOffsets = points.mapIndexed { idx, p -> pointOffset(idx, p.validCount) }

                // Area gradient fill under Total line
                val areaPath = Path().apply {
                    val baseLineY = topPad + chartH
                    moveTo(totalOffsets.first().x, baseLineY)
                    totalOffsets.forEach { pt -> lineTo(pt.x, pt.y) }
                    lineTo(totalOffsets.last().x, baseLineY)
                    close()
                }
                drawPath(
                    path = areaPath,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            NeonCyan.copy(alpha = 0.34f),
                            NeonCyan.copy(alpha = 0.02f),
                        ),
                        startY = topPad,
                        endY = topPad + chartH,
                    ),
                )

                // Area gradient fill under Valid line
                val validAreaPath = Path().apply {
                    val baseLineY = topPad + chartH
                    moveTo(validOffsets.first().x, baseLineY)
                    validOffsets.forEach { pt -> lineTo(pt.x, pt.y) }
                    lineTo(validOffsets.last().x, baseLineY)
                    close()
                }
                drawPath(
                    path = validAreaPath,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            EmeraldValid.copy(alpha = 0.24f),
                            EmeraldValid.copy(alpha = 0.01f),
                        ),
                        startY = topPad,
                        endY = topPad + chartH,
                    ),
                )

                // Smooth line strokes
                val totalLine = Path().apply {
                    moveTo(totalOffsets.first().x, totalOffsets.first().y)
                    for (i in 1 until totalOffsets.size) {
                        val prev = totalOffsets[i - 1]
                        val curr = totalOffsets[i]
                        val midX = (prev.x + curr.x) / 2f
                        cubicTo(midX, prev.y, midX, curr.y, curr.x, curr.y)
                    }
                }
                drawPath(
                    path = totalLine,
                    color = NeonCyan,
                    style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
                )

                val validLine = Path().apply {
                    moveTo(validOffsets.first().x, validOffsets.first().y)
                    for (i in 1 until validOffsets.size) {
                        val prev = validOffsets[i - 1]
                        val curr = validOffsets[i]
                        val midX = (prev.x + curr.x) / 2f
                        cubicTo(midX, prev.y, midX, curr.y, curr.x, curr.y)
                    }
                }
                drawPath(
                    path = validLine,
                    color = EmeraldValid,
                    style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
                )

                // Selected crosshair & data point dots
                selectedIndex?.takeIf { it in points.indices }?.let { sel ->
                    val selTotal = totalOffsets[sel]
                    drawLine(
                        color = NeonCyan.copy(alpha = 0.45f),
                        start = Offset(selTotal.x, topPad),
                        end = Offset(selTotal.x, topPad + chartH),
                        strokeWidth = 1.5.dp.toPx(),
                    )
                }

                points.forEachIndexed { idx, p ->
                    val ptTotal = totalOffsets[idx]
                    val ptValid = validOffsets[idx]
                    val isSelected = idx == selectedIndex
                    drawCircle(
                        color = NeonCyan,
                        radius = if (isSelected) 6.dp.toPx() else 3.5.dp.toPx(),
                        center = ptTotal,
                    )
                    drawCircle(
                        color = EmeraldValid,
                        radius = if (isSelected) 5.dp.toPx() else 2.8.dp.toPx(),
                        center = ptValid,
                    )
                    if (p.dueCount > 0) {
                        drawCircle(
                            color = AmberDue,
                            radius = 3.dp.toPx(),
                            center = pointOffset(idx, p.dueCount),
                        )
                    }
                    if (p.blockedCount > 0) {
                        drawCircle(
                            color = CrimsonBlocked,
                            radius = 3.dp.toPx(),
                            center = pointOffset(idx, p.blockedCount),
                        )
                    }
                }
            }

            // Y-axis max and midpoint labels
            Column(
                modifier = Modifier
                    .padding(vertical = 8.dp)
                    .align(Alignment.TopStart),
                verticalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(text = "$maxY", style = MaterialTheme.typography.labelSmall, color = TextSecondary)
            }
            Text(
                text = "0",
                style = MaterialTheme.typography.labelSmall,
                color = TextSecondary,
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(bottom = 6.dp),
            )
        }

        XAxisDateLabels(points = points)
    }
}

@Composable
fun AttendanceStackedBarChart(
    points: List<DailyAttendancePoint>,
    selectedIndex: Int?,
    onSelectIndex: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (points.isEmpty()) return
    val maxY = (points.maxOfOrNull { it.totalCount } ?: 0).coerceAtLeast(4)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .testTag("attendance_bar_chart"),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(210.dp),
        ) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(points) {
                        detectTapGestures { offset ->
                            if (points.isNotEmpty() && size.width > 0) {
                                val slotW = size.width.toFloat() / points.size
                                val idx = (offset.x / slotW).toInt().coerceIn(0, points.lastIndex)
                                onSelectIndex(idx)
                            }
                        }
                    },
            ) {
                val leftPad = 24.dp.toPx()
                val rightPad = 8.dp.toPx()
                val topPad = 14.dp.toPx()
                val bottomPad = 12.dp.toPx()
                val chartW = (size.width - leftPad - rightPad).coerceAtLeast(1f)
                val chartH = (size.height - topPad - bottomPad).coerceAtLeast(1f)
                val dash = PathEffect.dashPathEffect(floatArrayOf(8f, 8f), 0f)

                for (i in 0..4) {
                    val y = topPad + chartH * (i / 4f)
                    drawLine(
                        color = Color.White.copy(alpha = 0.12f),
                        start = Offset(leftPad, y),
                        end = Offset(leftPad + chartW, y),
                        strokeWidth = 1.dp.toPx(),
                        pathEffect = dash,
                    )
                }

                val slotW = chartW / points.size
                val barW = (slotW * 0.56f).coerceIn(6.dp.toPx(), 24.dp.toPx())

                points.forEachIndexed { idx, p ->
                    val x = leftPad + idx * slotW + (slotW - barW) / 2f
                    if (idx == selectedIndex) {
                        drawRoundRect(
                            color = NeonCyan.copy(alpha = 0.14f),
                            topLeft = Offset(leftPad + idx * slotW, topPad),
                            size = Size(slotW, chartH),
                            cornerRadius = CornerRadius(6.dp.toPx()),
                        )
                    }

                    var currentBottom = topPad + chartH
                    val segments = listOf(
                        p.validCount to EmeraldValid,
                        p.dueCount to AmberDue,
                        p.blockedCount to CrimsonBlocked,
                    )
                    segments.forEach { (count, segColor) ->
                        if (count > 0) {
                            val segH = (count.toFloat() / maxY.toFloat()) * chartH
                            val segTop = (currentBottom - segH).coerceAtLeast(topPad)
                            drawRoundRect(
                                color = segColor,
                                topLeft = Offset(x, segTop),
                                size = Size(barW, (currentBottom - segTop).coerceAtLeast(2f)),
                                cornerRadius = CornerRadius(4.dp.toPx()),
                            )
                            currentBottom = segTop
                        }
                    }
                }
            }

            Text(
                text = "$maxY",
                style = MaterialTheme.typography.labelSmall,
                color = TextSecondary,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(top = 6.dp),
            )
            Text(
                text = "0",
                style = MaterialTheme.typography.labelSmall,
                color = TextSecondary,
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(bottom = 6.dp),
            )
        }

        XAxisDateLabels(points = points)
    }
}

@Composable
private fun XAxisDateLabels(points: List<DailyAttendancePoint>) {
    if (points.isEmpty()) return
    val stride = when {
        points.size <= 7 -> 1
        points.size <= 14 -> 3
        else -> 6
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 24.dp, end = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        points.forEachIndexed { index, pt ->
            if (index == 0 || index == points.lastIndex || index % stride == 0) {
                Text(
                    text = pt.shortLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = TextSecondary,
                )
            }
        }
    }
}
