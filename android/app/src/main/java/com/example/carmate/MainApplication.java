package com.example.carmate;

import io.flutter.app.FlutterApplication;
import android.util.Log;
import com.example.carmate.util.AutoConnector;

/**
 * Classe Application principale che inizializza Android Auto
 */
public class MainApplication extends FlutterApplication {
    
    private static final String TAG = "FlutterAutoApp";
    private AutoConnector autoConnector;
    
    @Override
    public void onCreate() {
        super.onCreate();
        
        // Inizializza il connettore Auto
        Log.d(TAG, "Inizializzazione MainApplication");
        autoConnector = new AutoConnector(this);
        autoConnector.initializeAutoConnection();
        
        if (autoConnector.isConnectedToAuto()) {
            Log.d(TAG, "L'applicazione è connessa ad Android Auto all'avvio");
        } else {
            Log.d(TAG, "L'applicazione non è connessa ad Android Auto all'avvio");
        }
    }
    
    /**
     * Ottiene l'istanza del connettore Auto
     */
    public AutoConnector getAutoConnector() {
        return autoConnector;
    }
}
