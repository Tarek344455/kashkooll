package com.dig.kashkool.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import kotlinx.serialization.Serializable
import java.util.UUID

enum class ResourceType(val key: String) {
    HUMAN("human"),
    TOOL("tool"),
    FINANCIAL("financial");

    companion object {
        fun fromKey(raw: String): ResourceType =
            entries.firstOrNull { it.key.equals(raw, ignoreCase = true) } ?: TOOL
    }
}

enum class AvailabilityStatus(val key: String) {
    AVAILABLE("available"),
    IN_USE("in_use"),
    RESERVED("reserved"),
    UNAVAILABLE("unavailable");

    companion object {
        fun fromKey(raw: String): AvailabilityStatus =
            entries.firstOrNull { it.key.equals(raw, ignoreCase = true) } ?: AVAILABLE
    }
}

@Serializable
@Entity(
    tableName = "resources",
    indices = [
        Index(value = ["tenant_id"]),
        Index(value = ["type", "availability_status"]),
    ],
)
data class Resource(
    @PrimaryKey
    val id: String = "res-${UUID.randomUUID()}",
    val name: String,
    val type: ResourceType,
    @ColumnInfo(name = "availability_status")
    val availabilityStatus: AvailabilityStatus = AvailabilityStatus.AVAILABLE,
    @ColumnInfo(name = "tenant_id")
    val tenantId: String = "demo-centre",
    @ColumnInfo(name = "cost_piasters")
    val costPiasters: Long = 0L,
    @ColumnInfo(name = "sync_status")
    val syncStatus: String = "pending",
    @ColumnInfo(name = "updated_at_millis")
    val updatedAtMillis: Long = System.currentTimeMillis(),
)

class ResourceConverters {
    @TypeConverter
    fun fromResourceType(type: ResourceType): String = type.key

    @TypeConverter
    fun toResourceType(raw: String): ResourceType = ResourceType.fromKey(raw)

    @TypeConverter
    fun fromAvailabilityStatus(status: AvailabilityStatus): String = status.key

    @TypeConverter
    fun toAvailabilityStatus(raw: String): AvailabilityStatus = AvailabilityStatus.fromKey(raw)
}
