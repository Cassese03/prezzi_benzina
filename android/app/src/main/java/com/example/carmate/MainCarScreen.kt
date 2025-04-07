package com.example.carmate

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import androidx.core.graphics.drawable.IconCompat
import android.util.Log
import androidx.car.app.constraints.ConstraintManager
import com.example.carmate.screens.AveragePricesScreen
import com.example.carmate.screens.NearestStationsPage
import com.example.carmate.util.FlutterBridge

/**
 * Schermata principale per Android Auto
 */
class MainCarScreen(carContext: CarContext) : Screen(carContext) {
    private val TAG = "MainCarScreen"
    private val flutterBridge by lazy { FlutterBridge(carContext) }
    
    override fun onGetTemplate(): Template {
        Log.d(TAG, "Creazione template principale")
        
        val listBuilder = ItemList.Builder()
            .addItem(createRow("Trova Distributori", "Cerca distributori vicino a te", R.drawable.ic_gas_station))
            .addItem(createRow("Prezzi Medi", "Visualizza prezzi medi dei carburanti", R.drawable.ic_price_tag))
            .addItem(createRow("Rifornimenti", "Gestisci i tuoi rifornimenti", R.drawable.ic_refueling))

        return ListTemplate.Builder()
            .setSingleList(listBuilder.build())
            .setTitle("CarMate")
            .setHeaderAction(Action.BACK)
            .build()
    }

    private fun createRow(title: String, subtitle: String, iconResId: Int): Row {
        return Row.Builder()
            .setTitle(title)
            .addText(subtitle)
            .setImage(
                CarIcon.Builder(
                    IconCompat.createWithResource(carContext, iconResId)
                ).build()
            )
            .setOnClickListener {
                when (title) {
                    "Trova Distributori" -> {
                        Log.d(TAG, "Navigazione verso schermata Prezzi Medi")
                        screenManager.push(NearestStationsPage(carContext, flutterBridge))
                    }
                    "Prezzi Medi" -> {
                        Log.d(TAG, "Navigazione verso schermata Prezzi Medi")
                        screenManager.push(AveragePricesScreen(carContext, flutterBridge))
                    }
                    "Rifornimenti" -> screenManager.push(createSimpleMessageScreen("Rifornimenti", "Funzionalità non disponibile"))
                }
            }
            .build()
    }
    
    private fun createSimpleMessageScreen(title: String, message: String): Screen {
        return object : Screen(carContext) {
            override fun onGetTemplate(): Template {
                return MessageTemplate.Builder(message)
                    .setTitle(title)
                    .setHeaderAction(Action.BACK)
                    .addAction(Action.Builder()
                        .setTitle("OK")
                        .setOnClickListener { screenManager.pop() }
                        .build())
                    .build()
            }
        }
    }
}
