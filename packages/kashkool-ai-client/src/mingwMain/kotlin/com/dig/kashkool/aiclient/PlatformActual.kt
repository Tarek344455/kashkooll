package com.dig.kashkool.aiclient

/** Windows (MinGW): read env vars from the process environment via java.lang.System. */
internal actual fun getEnv(key: String): String? = java.lang.System.getenv(key)
