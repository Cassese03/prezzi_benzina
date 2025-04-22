package com.lorenzo.tankfuel.screens

import android.os.Handler
import android.os.Looper
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import android.util.Log
import androidx.core.graphics.drawable.IconCompat
import com.lorenzo.tankfuel.R
import com.lorenzo.tankfuel.util.FlutterBridge
import com.lorenzo.tankfuel.util.Refueling
import com.lorenzo.tankfuel.util.Vehicle
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

/**
 * Schermata che mostra i rifornimenti dell'utente
 */
class RefuelingsPage(
    carContext: CarContext,
    private val flutterBridge: FlutterBridge
) : Screen(carContext) {
    private val TAG = "RefuelingsPage"
    private var isLoading = true
    private var refuelings = listOf<Refueling>()
    private var vehicles = listOf<Vehicle>()
    private var loadError: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private val dateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.ITALY)
    private val currencyFormat = NumberFormat.getCurrencyInstance(Locale.ITALY)
    
    init {
        loadData()
    }
    
    override fun onGetTemplate(): Template {
        return if (isLoading) {
            getLoadingTemplate()
        } else if (loadError != null) {
            getErrorTemplate(loadError!!)
        } else {
            getRefuelingsTemplate()
        }
    }
    
    private fun getLoadingTemplate(): Template {
        return MessageTemplate.Builder("Caricamento rifornimenti...")
            .setTitle("Rifornimenti")
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
                    loadData() 
                }
                .build())
            .build()
    }
    
    private fun getRefuelingsTemplate(): Template {
        val itemList = ItemList.Builder()
        
        if (refuelings.isEmpty()) {
            itemList.addItem(Row.Builder()
                .setTitle("Nessun rifornimento presente")
                .build())
        } else {
            refuelings.forEach { refueling ->
                // Trova il veicolo associato
                val vehicle = vehicles.find { it.id == refueling.vehicleId }
                val vehicleText = vehicle?.name ?: "Veicolo sconosciuto"
                
                itemList.addItem(Row.Builder()
                    .setTitle("${dateFormat.format(refueling.date)} - $vehicleText")
                    .addText("${refueling.liters} L a ${currencyFormat.format(refueling.pricePerLiter)}/L")
                    .addText("Totale: ${currencyFormat.format(refueling.totalAmount)} - ${refueling.kilometers} km")
                    .setOnClickListener {
                        showRefuelingDetails(refueling, vehicle)
                    }
                    .build())
            }
        }
        
        return ListTemplate.Builder()
            .setTitle("Rifornimenti")
            .setHeaderAction(Action.BACK)
            .setSingleList(itemList.build())
            .setActionStrip(ActionStrip.Builder()
                .addAction(Action.Builder()
                    .setIcon(CarIcon.Builder(
                        IconCompat.createWithResource(carContext, R.drawable.ic_add))
                        .build())
                    .setOnClickListener {
                        showAddRefuelingFlow()
                    }
                    .build())
                .build())
            .build()
    }
    
    private fun loadData() {
        Log.d(TAG, "Caricamento rifornimenti e veicoli...")
        isLoading = true
        
        // Carica prima i veicoli, poi i rifornimenti
        flutterBridge.getVehicles()
            .thenAccept { vehiclesResult ->
                Log.d(TAG, "Veicoli caricati: ${vehiclesResult.size}")
                vehicles = vehiclesResult
                
                if (vehicles.isEmpty()) {
                    // Mostra messaggio se non ci sono veicoli
                    isLoading = false
                    handler.post {
                        screenManager.push(createNoVehiclesScreen())
                    }
                    return@thenAccept
                }
                
                // Ora carica i rifornimenti
                flutterBridge.getRefuelings()
                    .thenAccept { refuelingsResult ->
                        Log.d(TAG, "Rifornimenti caricati: ${refuelingsResult.size}")
                        refuelings = refuelingsResult.sortedByDescending { it.date }
                        isLoading = false
                        loadError = null
                        
                        handler.post {
                            invalidate()
                        }
                    }
                    .exceptionally { throwable ->
                        Log.e(TAG, "Errore nel caricamento dei rifornimenti: ${throwable}")
                        isLoading = false
                        loadError = throwable.message ?: "Errore sconosciuto"
                        
                        handler.post {
                            invalidate()
                        }
                        
                        null
                    }
            }
            .exceptionally { throwable ->
                Log.e(TAG, "Errore nel caricamento dei veicoli: ${throwable}")
                isLoading = false
                loadError = throwable.message ?: "Errore sconosciuto"
                
                handler.post {
                    invalidate()
                }
                
                null
            }
    }
    
    /**
     * Crea una schermata che indica all'utente che non ci sono veicoli
     */
    private fun createNoVehiclesScreen(): Screen {
        return object : Screen(carContext) {
            override fun onGetTemplate(): Template {
                return MessageTemplate.Builder("Non esiste nessun veicolo. Prego crearlo nell'app principale.")
                    .setTitle("Nessun veicolo")
                    .setHeaderAction(Action.BACK)
                    .addAction(Action.Builder()
                        .setTitle("Torna indietro")
                        .setOnClickListener {Action.BACK}
                        .build())
                    .build()
            }
        }
    }
    
    private fun showRefuelingDetails(refueling: Refueling, vehicle: Vehicle?) {
        screenManager.push(object : Screen(carContext) {
            override fun onGetTemplate(): Template {
                val rows = mutableListOf<Row>()
                
                rows.add(Row.Builder()
                    .setTitle("Data")
                    .addText(dateFormat.format(refueling.date))
                    .build())
                
                rows.add(Row.Builder()
                    .setTitle("Veicolo")
                    .addText(vehicle?.name ?: "Sconosciuto")
                    .build())
                
                rows.add(Row.Builder()
                    .setTitle("Carburante")
                    .addText("${refueling.fuelType} - ${refueling.liters} litri")
                    .build())
                
                rows.add(Row.Builder()
                    .setTitle("Prezzo")
                    .addText("${currencyFormat.format(refueling.pricePerLiter)}/Litri - Totale: ${currencyFormat.format(refueling.totalAmount)}")
                    .build())
                
                rows.add(Row.Builder()
                    .setTitle("Chilometraggio")
                    .addText("${refueling.kilometers} km")
                    .build())
                
                if (refueling.consumption > 0) {
                    rows.add(Row.Builder()
                        .setTitle("Consumo")
                        .addText(String.format("%.2f L/100km", refueling.consumption))
                        .build())
                }
                
                if (!refueling.notes.isNullOrEmpty()) {
                    rows.add(Row.Builder()
                        .setTitle("Note")
                        .addText(refueling.notes)
                        .build())
                }
                
                val paneBuilder = Pane.Builder()
                rows.forEach { paneBuilder.addRow(it) }
                
                return PaneTemplate.Builder(paneBuilder.build())
                    .setTitle("Dettaglio Rifornimento")
                    .setHeaderAction(Action.BACK)
                    .build()
            }
        })
    }
    
    private fun showAddRefuelingFlow() {
        if (vehicles.isEmpty()) {
            screenManager.push(object : Screen(carContext) {
                override fun onGetTemplate(): Template {
                    return MessageTemplate.Builder("Devi prima aggiungere un veicolo nell'app principale.")
                        .setTitle("Nessun veicolo")
                        .setHeaderAction(Action.BACK)
                        .build()
                }
            })
            return
        }
        
        // Prima schermata: selezione del veicolo
        screenManager.push(object : Screen(carContext) {
            private var selectedVehicleId: String? = null
            
            override fun onGetTemplate(): Template {
                val itemList = ItemList.Builder()
                
                vehicles.forEach { vehicle ->
                    itemList.addItem(Row.Builder()
                        .setTitle(vehicle.name)
                        .addText("${vehicle.brand} ${vehicle.model} - ${vehicle.fuelType}")
                        .setOnClickListener {
                            selectedVehicleId = vehicle.id
                            showFuelPriceInput(vehicle)
                        }
                        .build())
                }
                
                return ListTemplate.Builder()
                    .setTitle("Seleziona Veicolo")
                    .setHeaderAction(Action.BACK)
                    .setSingleList(itemList.build())
                    .build()
            }
            
            private fun showFuelPriceInput(vehicle: Vehicle) {
                showAddRefuelingDetails(vehicle)
            }
        })
    }
    
    private fun showAddRefuelingDetails(vehicle: Vehicle) {
        screenManager.push(object : Screen(carContext) {
            override fun onGetTemplate(): Template {
                return MessageTemplate.Builder(
                    "Per ragioni di sicurezza alla guida, i dettagli del rifornimento " +
                    "devono essere inseriti nell'app principale.\n\n" +
                    "Utilizza l'app CarMate sul tuo smartphone per aggiungere un nuovo rifornimento " +
                    "per il veicolo ${vehicle.name}."
                )
                    .setTitle("Aggiungi Rifornimento")
                    .setHeaderAction(Action.BACK)
                    .addAction(Action.Builder()
                        .setTitle("Ho capito")
                        .setOnClickListener { 
                            Action.BACK
                        }
                        .build())
                    .build()
            }
        })
    }
}
