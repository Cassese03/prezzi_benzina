package com.example.carmate.util

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CompletableFuture

/**
 * Ponte di comunicazione tra Android Auto e Flutter
 */
class FlutterBridge(private val context: Context) {
    private val TAG = "FlutterBridge"
    private val CHANNEL_NAME = "com.example.carmate/auto"
    private val ENGINE_ID = "auto_engine"
    
    private var methodChannel: MethodChannel? = null
    private var flutterEngine: FlutterEngine? = null
    
    init {
        setupFlutterEngine()
    }
    
    private fun setupFlutterEngine() {
        try {
            // Ottieni il FlutterEngine dall'applicazione principale
            val app = context.applicationContext
            
            // Cerca di ottenere un engine esistente
            flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
            
            if (flutterEngine == null) {
                Log.d(TAG, "Creazione nuovo FlutterEngine")
                
                // Crea un nuovo engine
                flutterEngine = FlutterEngine(context)
                
                // Verifica che l'engine non sia null prima di continuare
                if (flutterEngine != null) {
                    // Inizializza il Dart VM
                    flutterEngine?.dartExecutor?.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint.createDefault()
                    )
                    
                    // Salva in cache per riutilizzo
                    FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
                }
            } else {
                Log.d(TAG, "FlutterEngine già esistente")
            }
            
            // Verifica che l'engine sia stato creato correttamente
            if (flutterEngine == null) {
                Log.e(TAG, "Impossibile inizializzare FlutterEngine")
                return
            }
            
            // Imposta il canale di comunicazione con verifica di null safety
            val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
            if (binaryMessenger != null) {
                methodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
                Log.d(TAG, "MethodChannel inizializzato correttamente")
            } else {
                Log.e(TAG, "BinaryMessenger è null, impossibile creare MethodChannel")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Errore nell'inizializzazione di FlutterEngine: ${e.message}", e)
        }
    }
    
    /**
     * Ottiene i prezzi medi dei carburanti da Flutter
     */
    fun getAveragePrices(): CompletableFuture<List<FuelPrice>> {
        val future = CompletableFuture<List<FuelPrice>>()
        
        try {
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel non inizializzato")
                future.completeExceptionally(Exception("MethodChannel non inizializzato"))
                return future
            }
            
            methodChannel?.invokeMethod("getAveragePrices", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    try {
                        val pricesList = mutableListOf<FuelPrice>()
                        
                        // Converte il risultato in una lista di FuelPrice
                        if (result is List<*>) {
                            for (item in result) {
                                if (item is Map<*, *>) {
                                    val fuelType = item["fuelType"] as? String ?: "Sconosciuto"
                                    val price = (item["price"] as? Double) ?: 0.0
                                    val date = item["date"] as? String ?: "Oggi"
                                    val region = item["region"] as? String ?: "Italia"
                                    
                                    pricesList.add(FuelPrice(fuelType, price, date, region))
                                }
                            }
                        }
                        
                        // Se non ci sono dati, aggiungi alcuni dati di esempio
                        if (pricesList.isEmpty()) {
                            Log.d(TAG, "Nessun dato ricevuto, usando dati di fallback")
                            pricesList.addAll(
                                listOf(
                                    FuelPrice("Benzina", 1.789, "2023-10-15", "Media nazionale"),
                                    FuelPrice("Diesel", 1.659, "2023-10-15", "Media nazionale"),
                                    FuelPrice("GPL", 0.765, "2023-10-15", "Media nazionale"),
                                    FuelPrice("Metano", 1.599, "2023-10-15", "Media nazionale")
                                )
                            )
                        }
                        
                        Log.d(TAG, "Prezzi carburanti recuperati: ${pricesList.size}")
                        future.complete(pricesList)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Errore nell'elaborazione dei prezzi: ${e.message}", e)
                        future.completeExceptionally(e)
                    }
                }
                
                override fun error(code: String, message: String?, details: Any?) {
                    Log.e(TAG, "2.Errore nella chiamata a Flutter: $code - $message")
                    
                    // Fornisci dati di fallback in caso di errore
                    val fallbackData = listOf(
                        FuelPrice("Benzina", 1.789, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("Diesel", 1.659, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("GPL", 0.765, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("Metano", 1.599, "2023-10-15", "Media nazionale (fallback)")
                    )
                    
                    Log.d(TAG, "Utilizzo dati di fallback a causa dell'errore")
                    future.complete(fallbackData)
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "Metodo non implementato in Flutter")
                    
                    // Fornisci dati di fallback
                    val fallbackData = listOf(
                        FuelPrice("Benzina", 1.789, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("Diesel", 1.659, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("GPL", 0.765, "2023-10-15", "Media nazionale (fallback)"),
                        FuelPrice("Metano", 1.599, "2023-10-15", "Media nazionale (fallback)")
                    )
                    
                    Log.d(TAG, "Utilizzo dati di fallback poiché il metodo non è implementato")
                    future.complete(fallbackData)
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Errore nell'invocazione del metodo: ${e.message}", e)
            
            // Fornisci dati di fallback
            val fallbackData = listOf(
                FuelPrice("Benzina", 1.789, "2023-10-15", "Media nazionale (fallback)"),
                FuelPrice("Diesel", 1.659, "2023-10-15", "Media nazionale (fallback)"),
                FuelPrice("GPL", 0.765, "2023-10-15", "Media nazionale (fallback)"),
                FuelPrice("Metano", 1.599, "2023-10-15", "Media nazionale (fallback)")
            )
            
            Log.d(TAG, "Utilizzo dati di fallback a causa dell'eccezione")
            future.complete(fallbackData)
        }
        
        return future
    }
    
    /**
     * Ottiene le stazioni di rifornimento più vicine
     */
    fun getNearestStations(): CompletableFuture<List<GasStation>> {
        val future = CompletableFuture<List<GasStation>>()
        
        try {
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel non inizializzato")
                // Fornisci dati di fallback
                val fallbackData = createFallbackStations()
                future.complete(fallbackData)
                return future
            }
            
            methodChannel?.invokeMethod("getNearestStations", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    try {
                        val stationsList = mutableListOf<GasStation>()
                        Log.d(TAG, "Result from Flutter: $stationsList")
                        // Converte il risultato in una lista di stazioni
                        if (result is List<*>) {
                            for (item in result) {
                                if (item is Map<*, *>) {
                                    val id = item["id"] as? String ?: ""
                                    val name = item["name"] as? String ?: "Stazione sconosciuta"
                                    val address = item["address"] as? String ?: ""
                                    val self = (item["self"] as? Double) ?: 0.0
                                    val servito = (item["servito"] as? Double) ?: 0.0
                                    val lat = (item["lat"] as? Double) ?: 0.0
                                    val lon = (item["lon"] as? Double) ?: 0.0
                                    
                                    stationsList.add(GasStation(id, name, address, self,servito,lat,lon))
                                }
                            }
                        }
                        
                        // Se non ci sono dati, aggiungi alcuni dati di esempio
                        if (stationsList.isEmpty()) {
                            Log.d(TAG, "Nessuna stazione ricevuta, usando dati di fallback")
                            stationsList.addAll(createFallbackStations())
                        }
                        
                        Log.d(TAG, "Stazioni recuperate: ${stationsList.size}")
                        future.complete(stationsList)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Errore nell'elaborazione delle stazioni: ${e.message}", e)
                        future.complete(createFallbackStations())
                    }
                }
                
                override fun error(code: String, message: String?, details: Any?) {
                    Log.e(TAG, "3.Errore nella chiamata a Flutter: $code - $message")
                    future.complete(createFallbackStations())
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "Metodo non implementato in Flutter")
                    future.complete(createFallbackStations())
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Errore nell'invocazione del metodo: ${e.message}", e)
            future.complete(createFallbackStations())
        }
        
        return future
    }
    
    private fun createFallbackStations(): List<GasStation> {
        return listOf(
            GasStation("1", "Eni Station", "Via Roma 123, Milano", 1.789, 1.789,0.00,0.00),
            GasStation("2", "Q8", "Viale Monza 45, Milano", 1.769, 1.789,0.00,0.00),
            GasStation("3", "Tamoil", "Corso Buenos Aires 78, Milano", 1.759, 1.789,0.00,0.00),
            GasStation("4", "IP", "Via Torino 56, Milano", 1.779, 1.789,0.00,0.00)
        )
    }
}

/**
 * Modello dati per i prezzi dei carburanti
 */
data class FuelPrice(
    val fuelType: String,
    val price: Double,
    val date: String,
    val region: String
)

/**
 * Modello dati per le stazioni di rifornimento
 */
data class GasStation(
    val id: String,
    val name: String,
    val address: String,
    val self: Double,
    val servito: Double,
    val lat: Double,
    val lon: Double
)
