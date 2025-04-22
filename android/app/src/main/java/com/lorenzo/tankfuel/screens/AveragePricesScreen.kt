package com.lorenzo.tankfuel.screens

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import android.util.Log
import com.lorenzo.tankfuel.R
import com.lorenzo.tankfuel.util.FlutterBridge
import com.lorenzo.tankfuel.util.FuelPrice
import java.text.NumberFormat
import java.util.Locale

/**
 * Schermata che mostra i prezzi medi del carburante ottenuti da Flutter
 * Non è necessario modificare questa schermata poiché non dipende dai veicoli
 */
class AveragePricesScreen(
    carContext: CarContext,
    private val flutterBridge: FlutterBridge
) : Screen(carContext) {
    private val TAG = "AveragePricesScreen"
    private var isLoading = true
    private var prices = listOf<FuelPrice>()
    private var loadError: String? = null
    private val handler = Handler(Looper.getMainLooper())
    
    init {
        loadPrices()
    }
    
    override fun onGetTemplate(): Template {
        return if (isLoading) {
            // Mostra schermata di caricamento
            getLoadingTemplate()
        } else if (loadError != null) {
            // Mostra errore
            getErrorTemplate(loadError!!)
        } else {
            // Mostra i prezzi
            getPricesTemplate()
        }
    }
    
    private fun getLoadingTemplate(): Template {
        // Usiamo un MessageTemplate invece di LoadingTemplate che potrebbe non essere disponibile
        return MessageTemplate.Builder("Caricamento dei prezzi in corso...")
            .setTitle("Prezzi Medi")
            .setHeaderAction(Action.BACK)
            .build()
    }
    
    private fun getErrorTemplate(error: String): Template {
        return MessageTemplate.Builder("Si è verificato un errore: $error")
            .setTitle("Errore")
            .setHeaderAction(Action.BACK)
            .addAction(Action.Builder()
                .setTitle("Riprova")
                .setOnClickListener { 
                    isLoading = true
                    invalidate()
                    loadPrices() 
                }
                .build())
            .build()
    }
    
    private fun getPricesTemplate(): Template {
        val itemList = ItemList.Builder()
        
        val currencyFormat = NumberFormat.getCurrencyInstance(Locale.ITALY)
        
        prices.forEach { price ->
            itemList.addItem(Row.Builder()
                .setTitle(price.fuelType)
                .addText("${currencyFormat.format(price.price)} al litro")
                .addText("Aggiornato: ${price.date}")
                .build())
        }
        
        return ListTemplate.Builder()
            .setTitle("Prezzi Medi - ${prices.firstOrNull()?.region ?: "Italia"}")
            .setHeaderAction(Action.BACK)
            .setSingleList(itemList.build())
            .build()
    }
    
    private fun loadPrices() {
        Log.d(TAG, "Caricamento prezzi...")
        isLoading = true
        
        flutterBridge.getAveragePrices()
            .thenAccept { result ->
                Log.d(TAG, "Prezzi caricati con successo: ${result.size}")
                prices = result
                isLoading = false
                loadError = null
                
                // Aggiorna l'interfaccia usando un Handler invece di ConstraintManager.getDispatcher
                handler.post {
                    invalidate()
                }
            }
            .exceptionally { throwable ->
                Log.e(TAG, "Errore nel caricamento dei prezzi: ${throwable.message}")
                isLoading = false
                loadError = throwable.message ?: "Errore sconosciuto"
                
                // Aggiorna l'interfaccia usando un Handler invece di ConstraintManager.getDispatcher
                handler.post {
                    invalidate()
                }
                
                null
            }
    }
}
