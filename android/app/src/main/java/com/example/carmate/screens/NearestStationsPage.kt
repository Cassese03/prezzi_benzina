package com.example.carmate.screens

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import android.util.Log
import com.example.carmate.R
import com.example.carmate.util.FlutterBridge
import com.example.carmate.util.GasStation
import java.text.NumberFormat
import java.util.Locale

/**
 * Schermata che mostra i distributori più vicini
 */
class NearestStationsPage(
    carContext: CarContext,
    private val flutterBridge: FlutterBridge
) : Screen(carContext) {
    private val TAG = "NearestStationsPage"
    private var isLoading = true
    private var stations = listOf<GasStation>()
    private var loadError: String? = null
    private val handler = Handler(Looper.getMainLooper())
    
    init {
        loadStations()
    }
    
    override fun onGetTemplate(): Template {
        return if (isLoading) {
            // Mostra schermata di caricamento
            getLoadingTemplate()
        } else if (loadError != null) {
            // Mostra errore
            getErrorTemplate(loadError!!)
        } else {
            // Mostra le stazioni
            getStationsTemplate()
        }
    }
    
    private fun getLoadingTemplate(): Template {
        return MessageTemplate.Builder("Ricerca distributori nelle vicinanze...")
            .setTitle("Distributori Vicini")
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
                    loadStations() 
                }
                .build())
            .build()
    }
    
    private fun getStationsTemplate(): Template {
        val itemList = ItemList.Builder()
        
        val currencyFormat = NumberFormat.getCurrencyInstance(Locale.ITALY)
        
        stations.forEach { station ->
            itemList.addItem(Row.Builder()
                .setTitle(station.name)
                .addText("Self :${currencyFormat.format(station.self)} - Servito :${currencyFormat.format(station.servito)} ${station.address}")
                .setOnClickListener {
                    showStationDetails(station)
                }
                .build())
        }
        
        return ListTemplate.Builder()
            .setTitle("Distributori Vicini")
            .setHeaderAction(Action.BACK)
            .setSingleList(itemList.build())
            .build()
    }
    
    private fun loadStations() {
        Log.d(TAG, "Caricamento stazioni...")
        isLoading = true
        
        flutterBridge.getNearestStations()
            .thenAccept { result ->
                Log.d(TAG, "Stazioni caricate con successo: ${result.size}")
                stations = result
                isLoading = false
                loadError = null
                
                handler.post {
                    invalidate()
                }
            }
            .exceptionally { throwable ->
                Log.e(TAG, "Errore nel caricamento delle pompe di benzina: ${throwable}")
                isLoading = false
                loadError = throwable.message ?: "Errore sconosciuto"
                
                handler.post {
                    invalidate()
                }
                
                null
            }
    }
    
    private fun showStationDetails(station: GasStation) {
        screenManager.push(object : Screen(carContext) {
            override fun onGetTemplate(): Template {
                return PaneTemplate.Builder(
                    Pane.Builder()
                        .addRow(Row.Builder()
                            .setTitle("Distributore")
                            .addText(station.name)
                            .build())
                        .addRow(Row.Builder()
                            .setTitle("Indirizzo")
                            .addText(station.address)
                            .build())
                        .addRow(Row.Builder()
                            .setTitle("Prezzo")
                            .addText("SELF: ${NumberFormat.getCurrencyInstance(Locale.ITALY).format(station.self)} al litro , SERVITO: ${NumberFormat.getCurrencyInstance(Locale.ITALY).format(station.servito)} al litro")
                            .build())
                        .addAction(
                            Action.Builder()
                                .setTitle("Naviga")
                                .setOnClickListener {
                                     try {
                                    val mapsIntent = Intent(Intent.ACTION_VIEW).apply {
                                        data = Uri.parse("google.navigation:q=${station.lat},${station.lon}")
                                        setPackage("com.google.android.apps.maps")
                                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                    }

                                    val packageManager = carContext.packageManager
                                    if (mapsIntent.resolveActivity(packageManager) != null) {
                                        carContext.startActivity(mapsIntent)
                                    } else {
                                        Log.e("NearestStationsPage", "Google Maps non è installato.")
                                    }
                                      } catch (e: Exception) {
                                         Log.e("NearestStationsPage", "Errore durante l'avvio della navigazione: ${e.message}")
                                     }
                                }
                                .build())
                        .build()
                        
                )
                .setTitle("Dettagli Distributore")
                .setHeaderAction(Action.BACK)
                .build()
            }
        })
    }
}
