package com.dig.kashkool

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.dig.kashkool.core.firebase.configureAppCheck
import com.dig.kashkool.ui.navigation.KashkoolApp
import com.dig.kashkool.ui.theme.KashkoolTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureAppCheck(this, intent)
        enableEdgeToEdge()
        setContent {
            KashkoolTheme {
                KashkoolApp()
            }
        }
    }
}