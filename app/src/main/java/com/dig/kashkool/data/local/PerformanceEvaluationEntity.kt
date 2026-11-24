package com.dig.kashkool.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

enum class EvaluationTargetType(val key: String) {
    TEACHER("teacher"),
    STUDENT("student"),
}

@Entity(tableName = "performance_evaluations")
data class PerformanceEvaluationEntity(
    @PrimaryKey val id: String = "eval-${UUID.randomUUID()}",
    @ColumnInfo(name = "target_id") val targetId: String,
    @ColumnInfo(name = "target_name") val targetName: String,
    @ColumnInfo(name = "target_type") val targetType: EvaluationTargetType,
    @ColumnInfo(name = "language_code") val languageCode: String,
    @ColumnInfo(name = "overall_score") val overallScore: Int,
    @ColumnInfo(name = "trust_badge") val trustBadge: String,
    @ColumnInfo(name = "analytical_summary") val analyticalSummary: String,
    @ColumnInfo(name = "instant_feedback") val instantFeedback: String,
    val strengths: List<String>,
    @ColumnInfo(name = "improvement_areas") val improvementAreas: List<String>,
    @ColumnInfo(name = "next_action_plan") val nextActionPlan: List<String>,
    @ColumnInfo(name = "trust_verification_note") val trustVerificationNote: String,
    @ColumnInfo(name = "evaluated_at_millis") val evaluatedAtMillis: Long = System.currentTimeMillis(),
)

class PerformanceEvaluationConverters {
    @TypeConverter
    fun fromTargetType(type: EvaluationTargetType): String = type.key

    @TypeConverter
    fun toTargetType(value: String): EvaluationTargetType =
        EvaluationTargetType.entries.firstOrNull { it.key == value } ?: EvaluationTargetType.STUDENT

    @TypeConverter
    fun fromStringList(items: List<String>): String = Json.encodeToString(items)

    @TypeConverter
    fun toStringList(raw: String): List<String> {
        if (raw.isBlank()) return emptyList()
        return runCatching { Json.decodeFromString<List<String>>(raw) }.getOrElse { emptyList() }
    }
}
