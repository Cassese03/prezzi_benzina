package com.lorenzo.tankfuel

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import androidx.core.graphics.drawable.IconCompat
import android.util.Log
import com.lorenzo.tankfuel.screens.AveragePricesScreen
import com.lorenzo.tankfuel.screens.NearestStationsPage
import com.lorenzo.tankfuel.screens.RefuelingsPage
import com.lorenzo.tankfuel.util.FlutterBridge

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
            .setTitle("TankFuel")
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
                        Log.d(TAG, "Navigazione verso schermata Trova Distributori")
                        screenManager.push(NearestStationsPage(carContext, flutterBridge))
                    }
                    "Prezzi Medi" -> {
                        Log.d(TAG, "Navigazione verso schermata Prezzi Medi")
                        screenManager.push(AveragePricesScreen(carContext, flutterBridge))
                    }
                    "Rifornimenti" -> {
                        Log.d(TAG, "Navigazione verso schermata Rifornimenti")
                        screenManager.push(RefuelingsPage(carContext, flutterBridge))
                    }
                }
            }
            .build()
    }
}
