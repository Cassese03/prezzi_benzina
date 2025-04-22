package com.lorenzo.tankfuel.util

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.CompletableFuture

/**
 * Ponte di comunicazione tra Android Auto e Flutter
 */
class FlutterBridge(private val context: Context) {
    private val TAG = "FlutterBridge"
    private val CHANNEL_NAME = "com.lorenzo.tankfuel/auto"
    private val ENGINE_ID = "auto_engine"
    
    private var methodChannel: MethodChannel? = null
    private var flutterEngine: FlutterEngine? = null
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    
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
    
    /**
     * Ottiene la lista dei rifornimenti da Flutter
     */
    fun getRefuelings(): CompletableFuture<List<Refueling>> {
        val future = CompletableFuture<List<Refueling>>()
        
        try {
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel non inizializzato")
                future.complete(createFallbackRefuelings())
                return future
            }
            
            methodChannel?.invokeMethod("getRefuelings", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    try {
                        val refuelingsList = mutableListOf<Refueling>()
                        
                        // Converte il risultato in una lista di Refueling
                        if (result is List<*>) {
                            for (item in result) {
                                if (item is Map<*, *>) {
                                    val id = item["id"] as? String ?: ""
                                    val dateStr = item["date"] as? String ?: dateFormat.format(Date())
                                    val date = try {
                                        if (dateStr.contains("T")) {
                                            dateFormat.parse(dateStr) ?: Date()
                                        } else {
                                            SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(dateStr) ?: Date()
                                        }
                                    } catch (e: Exception) {
                                        Date()
                                    }
                                    val liters = (item["liters"] as? Number)?.toDouble() ?: 0.0
                                    val pricePerLiter = (item["pricePerLiter"] as? Number)?.toDouble() ?: 0.0
                                    val kilometers = (item["kilometers"] as? Number)?.toDouble() ?: 0.0
                                    val totalAmount = (item["totalAmount"] as? Number)?.toDouble() ?: (liters * pricePerLiter)
                                    val fuelType = item["fuelType"] as? String ?: ""
                                    val notes = item["notes"] as? String
                                    val vehicleId = item["vehicleId"] as? String ?: ""
                                    
                                    refuelingsList.add(Refueling(
                                        id = id,
                                        date = date,
                                        liters = liters,
                                        pricePerLiter = pricePerLiter,
                                        kilometers = kilometers,
                                        totalAmount = totalAmount,
                                        fuelType = fuelType,
                                        notes = notes,
                                        vehicleId = vehicleId
                                    ))
                                }
                            }
                        }
                        
                        // Se non ci sono dati, utilizza i dati di fallback
                        //if (refuelingsList.isEmpty()) {
                        //    Log.d(TAG, "Nessun rifornimento ricevuto, usando dati di fallback")
                        //    refuelingsList.addAll(createFallbackRefuelings())
                        //}
                        
                        Log.d(TAG, "Rifornimenti recuperati: ${refuelingsList.size}")
                        future.complete(refuelingsList)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Errore nell'elaborazione dei rifornimenti: ${e.message}", e)
                        future.complete(createFallbackRefuelings())
                    }
                }
                
                override fun error(code: String, message: String?, details: Any?) {
                    Log.e(TAG, "Errore nella chiamata a Flutter: $code - $message")
                    future.complete(createFallbackRefuelings())
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "Metodo non implementato in Flutter")
                    future.complete(createFallbackRefuelings())
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Errore nell'invocazione del metodo: ${e.message}", e)
            future.complete(createFallbackRefuelings())
        }
        
        return future
    }
    
    /**
     * Ottiene la lista dei veicoli da Flutter
     */
    fun getVehicles(): CompletableFuture<List<Vehicle>> {
        val future = CompletableFuture<List<Vehicle>>()
        
        try {
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel non inizializzato")
                future.complete(createFallbackVehicles())
                return future
            }
            
            methodChannel?.invokeMethod("getVehicles", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    try {
                        val vehiclesList = mutableListOf<Vehicle>()
                        
                        // Converte il risultato in una lista di Vehicle
                        if (result is List<*>) {
                            for (item in result) {
                                if (item is Map<*, *>) {
                                    val id = item["id"] as? String ?: ""
                                    val name = item["name"] as? String ?: ""
                                    val brand = item["brand"] as? String ?: ""
                                    val model = item["model"] as? String ?: ""
                                    val fuelType = item["fuelType"] as? String ?: ""
                                    val year = (item["year"] as? Number)?.toInt() ?: 0
                                    val licensePlate = item["licensePlate"] as? String ?: ""
                                    
                                    vehiclesList.add(Vehicle(
                                        id = id,
                                        name = name,
                                        brand = brand,
                                        model = model,
                                        fuelType = fuelType,
                                        year = year,
                                        licensePlate = licensePlate
                                    ))
                                }
                            }
                        }
                        
                        // Se non ci sono dati, utilizza i dati di fallback
                        // if (vehiclesList.isEmpty()) {
                        //     Log.d(TAG, "Nessun veicolo ricevuto, usando dati di fallback")
                        //     vehiclesList.addAll(createFallbackVehicles())
                        // } 

                        Log.d(TAG, "Veicoli recuperati: ${vehiclesList.size}")
                        future.complete(vehiclesList)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Errore nell'elaborazione dei veicoli: ${e.message}", e)
                        future.complete(createFallbackVehicles())
                    }
                }
                
                override fun error(code: String, message: String?, details: Any?) {
                    Log.e(TAG, "Errore nella chiamata a Flutter: $code - $message")
                    future.complete(createFallbackVehicles())
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "Metodo non implementato in Flutter")
                    future.complete(createFallbackVehicles())
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Errore nell'invocazione del metodo: ${e.message}", e)
            future.complete(createFallbackVehicles())
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
    
    private fun createFallbackRefuelings(): List<Refueling> {
        val cal = Calendar.getInstance()
        
        // Crea alcuni rifornimenti di esempio
        val refuelings = mutableListOf<Refueling>()
        
        // Ultimo rifornimento (oggi)
        refuelings.add(Refueling(
            id = "1",
            date = cal.time,
            liters = 45.0,
            pricePerLiter = 1.789,
            kilometers = 12500.0,
            totalAmount = 80.50,
            fuelType = "Benzina",
            vehicleId = "1",
            notes = null
        ))
        
        // Rifornimento precedente (7 giorni fa)
        cal.add(Calendar.DAY_OF_MONTH, -7)
        refuelings.add(Refueling(
            id = "2",
            date = cal.time,
            liters = 40.0,
            pricePerLiter = 1.795,
            kilometers = 12200.0,
            totalAmount = 71.80,
            fuelType = "Benzina",
            vehicleId = "1",
            notes = "Autostrada"
        ))
        
        // Rifornimento ancora precedente (15 giorni fa)
        cal.add(Calendar.DAY_OF_MONTH, -8)
        refuelings.add(Refueling(
            id = "3",
            date = cal.time,
            liters = 50.0,
            pricePerLiter = 1.659,
            kilometers = 11850.0,
            totalAmount = 82.95,
            fuelType = "Diesel",
            vehicleId = "2",
            notes = "Viaggio lungo"
        ))
        
        return refuelings
    }
    
    private fun createFallbackVehicles(): List<Vehicle> {
        return listOf(
            Vehicle(
                id = "1",
                name = "La mia auto",
                brand = "Fiat",
                model = "Panda",
                fuelType = "Benzina",
                year = 2018,
                licensePlate = "AB123CD"
            ),
            Vehicle(
                id = "2",
                name = "Auto aziendale",
                brand = "Volkswagen",
                model = "Golf",
                fuelType = "Diesel",
                year = 2020,
                licensePlate = "XY456ZW"
            )
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

/**
 * Modello dati per i veicoli
 */
data class Vehicle(
    val id: String,
    val name: String,
    val brand: String,
    val model: String,
    val fuelType: String,
    val year: Int,
    val licensePlate: String
)

/**
 * Modello dati per i rifornimenti
 */
data class Refueling(
    val id: String,
    val date: Date,
    val liters: Double,
    val pricePerLiter: Double,
    val kilometers: Double,
    val totalAmount: Double,
    val fuelType: String,
    val vehicleId: String,
    val notes: String?
) {
    // Calcolo del consumo in L/100km
    val consumption: Double
        get() {
            // Se non c'è un chilometraggio precedente disponibile, non possiamo calcolare il consumo
            // In un'implementazione reale dovremmo confrontare con il rifornimento precedente
            return 0.0
        }
}
