package com.dig.kashkool.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(
    entities = [
        GroupEntity::class,
        StudentEntity::class,
        AttendanceEntity::class,
        LedgerEntryEntity::class,
        PaymentChannelEntity::class,
        PaymentSubmissionEntity::class,
        Resource::class,
        PerformanceEvaluationEntity::class,
    ],
    version = 4,
    exportSchema = false,
)
@TypeConverters(ResourceConverters::class, PerformanceEvaluationConverters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun kashkoolDao(): KashkoolDao

    companion object {
        @Volatile
        private var instance: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "kashkool_offline.db",
                ).fallbackToDestructiveMigration(dropAllTables = true).build().also { instance = it }
            }
        }
    }
}
