package com.dig.kashkool.aiclient

/** Linux: read env vars from the process environment via java.lang.System. */
internal actual fun getEnv(key: String): String? = java.lang.System.getenv(key)
