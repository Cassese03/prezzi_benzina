package com.lorenzo.tankfuel

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
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
    private val flutterBridge = FlutterBridge(carContext)
    
    override fun onGetTemplate(): Template {
        Log.d(TAG, "Creazione template principale")
        
        val listBuilder = ItemList.Builder()
        
        // Opzione per distributori più vicini
        listBuilder.addItem(
            Row.Builder()
                .setTitle("Distributori vicini")
                .addText("Trova i distributori di carburante nelle vicinanze")
                .setImage(
                    CarIcon.Builder(
                        IconCompat.createWithResource(
                            carContext,
                            R.drawable.ic_gas_station
                        )
                    ).build()
                )
                .setOnClickListener {
                    Log.d(TAG, "Apertura schermata distributori vicini")
                    screenManager.push(NearestStationsPage(carContext, flutterBridge))
                }
                .build()
        )
        
        // Opzione per prezzi medi
        listBuilder.addItem(
            Row.Builder()
                .setTitle("Prezzi medi carburante")
                .addText("Visualizza i prezzi medi del carburante")
                .setImage(
                    CarIcon.Builder(
                        IconCompat.createWithResource(
                            carContext,
                            R.drawable.ic_price_tag
                        )
                    ).build()
                )
                .setOnClickListener {
                    Log.d(TAG, "Apertura schermata prezzi medi")
                    screenManager.push(AveragePricesScreen(carContext, flutterBridge))
                }
                .build()
        )
        
        // Opzione per rifornimenti
        listBuilder.addItem(
            Row.Builder()
                .setTitle("I miei rifornimenti")
                .addText("Visualizza e gestisci i rifornimenti")
                .setImage(
                    CarIcon.Builder(
                        IconCompat.createWithResource(
                            carContext,
                            R.drawable.ic_refueling
                        )
                    ).build()
                )
                .setOnClickListener {
                    Log.d(TAG, "Apertura schermata rifornimenti")
                    screenManager.push(RefuelingsPage(carContext, flutterBridge))
                }
                .build()
        )
        
        return ListTemplate.Builder()
            .setTitle("TankFuel")  // Cambiato da CarMate a TankFuel
            .setHeaderAction(Action.APP_ICON)
            .setSingleList(listBuilder.build())
            .build()
    }
}
