package com.example.carmate

import android.content.Intent
import android.util.Log
import androidx.car.app.CarAppService
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

/**
 * Servizio principale per Android Auto
 */
class CarMateService : CarAppService() {
    private val TAG = "CarMateService"
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CarMateService creato")
    }
    
    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(): Session {
        Log.d(TAG, "Creazione nuova sessione")
        return CarMateSession()
    }
}

/**
 * Sessione per Android Auto
 */
class CarMateSession : Session() {
    private val TAG = "CarMateSession"
    
    override fun onCreateScreen(intent: Intent): Screen {
        Log.d(TAG, "Creazione schermata iniziale")
        return MainCarScreen(carContext)
    }
}
