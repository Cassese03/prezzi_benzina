File Principali
[main.dart`]
Funzione: Punto di ingresso dell'applicazione
Descrizione: Configura l'applicazione, inizializza i servizi necessari e richiede i permessi all'avvio se necessario
Componente principale: MyApp che imposta il tema e la home page
[home_page.dart`]
Funzione: Schermata principale dell'app
Descrizione: Mostra una mappa con le stazioni di benzina e quattro tab di navigazione per diverse visualizzazioni (km vicini, più economici, prezzo medio, statistiche)
Funzionalità chiave: Geolocalizzazione, visualizzazione mappa, caricamento dati CSV, gestione storage alternativo
[csv_viewer_page.dart`](untitled:/%60/c%3A[CSV_SERVICE] Download file stazioni completato
[CSV_SERVICE] Avvio download da https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv
[CSV_SERVICE] Salvataggio file in /data/user/0/com.example.carmate/app_flutter/gas_prices.csv
[CSV_SERVICE] RIGA 3: 59183;ENIMOOV S.P.A.;Agip Eni;Stradale;19829 AGRIGENTO;SS.189 KM. 64+649 - C.DA SAN MICHELE  S.N.C  ;AGRIGENTO;AG;37.333935;13.595533
[CSV_SERVICE] RIGA 4: 23778;ALFONSO DI BENEDETTO CARBURANTI LUBRIFICANTI SRL;Sicilpetroli;Stradale;A. Di Benedetto srl Via Imera Ag;VIA IMERA SN 92100, AGRIGENTO (AG) 10 92100;AGRIGENTO;AG;37.312390927445705;13.58591309570079
[CSV_SERVICE] Headers richiesta: {User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36, Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8, Accept-Language: it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7}
GitHub Copilot
Spiegazione dei File dell'App Prezzi Benzina
Ecco una spiegazione file per file di cosa fa ogni componente dell'applicazione:

File Principali
[main.dart`]
Funzione: Punto di ingresso dell'applicazione
Descrizione: Configura l'applicazione, inizializza i servizi necessari e richiede i permessi all'avvio se necessario
Componente principale: MyApp che imposta il tema e la home page
[home_page.dart`]
Funzione: Schermata principale dell'app
Descrizione: Mostra una mappa con le stazioni di benzina e quattro tab di navigazione per diverse visualizzazioni (km vicini, più economici, prezzo medio, statistiche)
Funzionalità chiave: Geolocalizzazione, visualizzazione mappa, caricamento dati CSV, gestione storage alternativo
[csv_viewer_page.dart`]
Funzione: Visualizzatore dei file CSV
Descrizione: Permette all'utente di vedere il contenuto dei file CSV scaricati (stazioni e prezzi)
Funzionalità chiave: Lettura file con diversi encoding, visualizzazione tabulare, gestione errori di formato
[custom_csv_page.dart`]
Funzione: Importazione di file CSV personalizzati
Descrizione: Consente all'utente di selezionare manualmente file CSV e importarli nell'app
Funzionalità chiave: Selezione file, anteprima contenuto, importazione dati
[vehicles_page.dart`]
Funzione: Gestione veicoli
Descrizione: Permette di aggiungere, modificare ed eliminare veicoli dell'utente
Funzionalità chiave: CRUD per veicoli, selezione veicolo attivo
[car_stats_page.dart`]
Funzione: Statistiche veicoli e rifornimenti
Descrizione: Visualizza statistiche sui rifornimenti, consumi e costi per veicolo
Funzionalità chiave: Dashboard con statistiche, grafici, gestione rifornimenti, calcoli consumi
Servizi
[gas_station_service.dart`]
Funzione: Servizio principale per i dati delle stazioni
Descrizione: Gestisce accesso, recupero e filtraggio dei dati delle stazioni di rifornimento
Funzionalità chiave: Recupero stazioni vicine, debug file CSV, riparazione file corrotti
[csv_gas_station_service.dart`]
Funzione: Gestione download e parsing CSV
Descrizione: Si occupa di scaricare, memorizzare e analizzare i file CSV con i dati delle stazioni
Funzionalità chiave: Download file, parsing CSV, gestione encoding, storage alternativo
[preferences_service.dart`]
Funzione: Gestione preferenze utente
Descrizione: Salva e carica le preferenze dell'utente (veicoli, impostazioni)
Funzionalità chiave: Persistenza dati, gestione veicoli preferiti
Modelli
[gas_station.dart`]
Funzione: Modello per le stazioni di rifornimento
Descrizione: Rappresenta una stazione di benzina con i suoi attributi
Attributi chiave: id, nome, coordinate, indirizzo, prezzi dei carburanti
[vehicle.dart`]
Funzione: Modello per i veicoli
Descrizione: Rappresenta un veicolo dell'utente
Attributi chiave: id, nome, marca, modello, tipo carburante, anno, targa
[refueling.dart`]
Funzione: Modello per i rifornimenti
Descrizione: Rappresenta un singolo rifornimento di carburante
Attributi chiave: id, data, litri, prezzo al litro, chilometri, tipo carburante, veicolo
Utilities
[permission_handler.dart`]
Funzione: Gestione permessi di storage
Descrizione: Verifica e richiede i permessi necessari per accedere allo storage
Funzionalità chiave: Richiesta permessi, ricerca percorsi scrivibili
Mappa Concettuale dell'Applicazione
/xampp/htdocs/prezzi_benzina/lib/screens/csv_viewer_page.dart%60)
Funzione: Visualizzatore dei file CSV
Descrizione: Permette all'utente di vedere il contenuto dei file CSV scaricati (stazioni e prezzi)
Funzionalità chiave: Lettura file con diversi encoding, visualizzazione tabulare, gestione errori di formato
[custom_csv_page.dart`]
Funzione: Importazione di file CSV personalizzati
Descrizione: Consente all'utente di selezionare manualmente file CSV e importarli nell'app
Funzionalità chiave: Selezione file, anteprima contenuto, importazione dati
[vehicles_page.dart`]
Funzione: Gestione veicoli
Descrizione: Permette di aggiungere, modificare ed eliminare veicoli dell'utente
Funzionalità chiave: CRUD per veicoli, selezione veicolo attivo
[car_stats_page.dart`]
Funzione: Statistiche veicoli e rifornimenti
Descrizione: Visualizza statistiche sui rifornimenti, consumi e costi per veicolo
Funzionalità chiave: Dashboard con statistiche, grafici, gestione rifornimenti, calcoli consumi
Servizi
[gas_station_service.dart`]
Funzione: Servizio principale per i dati delle stazioni
Descrizione: Gestisce accesso, recupero e filtraggio dei dati delle stazioni di rifornimento
Funzionalità chiave: Recupero stazioni vicine, debug file CSV, riparazione file corrotti
[csv_gas_station_service.dart`]
Funzione: Gestione download e parsing CSV
Descrizione: Si occupa di scaricare, memorizzare e analizzare i file CSV con i dati delle stazioni
Funzionalità chiave: Download file, parsing CSV, gestione encoding, storage alternativo
[preferences_service.dart`]
Funzione: Gestione preferenze utente
Descrizione: Salva e carica le preferenze dell'utente (veicoli, impostazioni)
Funzionalità chiave: Persistenza dati, gestione veicoli preferiti
Modelli
[gas_station.dart`]
Funzione: Modello per le stazioni di rifornimento
Descrizione: Rappresenta una stazione di benzina con i suoi attributi
Attributi chiave: id, nome, coordinate, indirizzo, prezzi dei carburanti
[vehicle.dart`]
Funzione: Modello per i veicoli
Descrizione: Rappresenta un veicolo dell'utente
Attributi chiave: id, nome, marca, modello, tipo carburante, anno, targa
[refueling.dart`]
Funzione: Modello per i rifornimenti
Descrizione: Rappresenta un singolo rifornimento di carburante
Attributi chiave: id, data, litri, prezzo al litro, chilometri, tipo carburante, veicolo
Utilities
[permission_handler.dart`]
Funzione: Gestione permessi di storage
Descrizione: Verifica e richiede i permessi necessari per accedere allo storage
Funzionalità chiave: Richiesta permessi, ricerca percorsi scrivibili
Mappa Concettuale dell'Applicazione
Flusso dati principale dell'applicazione:
L'utente apre l'app che viene avviata da main.dart
home_page.dart inizializza lo storage alternativo e richiede la posizione
gas_station_service.dart scarica i file CSV tramite csv_gas_station_service.dart
I file CSV vengono parsati e convertiti in oggetti GasStation
Le stazioni vengono filtrate per distanza e mostrate sulla mappa
L'utente può aggiungere veicoli tramite vehicles_page.dart
L'utente può registrare rifornimenti e vedere statistiche in car_stats_page.dart
L'utente può visualizzare o importare file CSV manualmente tramite csv_viewer_page.dart e custom_csv_page.dart
Questa struttura segue il pattern MVC (Model-View-Controller) dove i Models rappresentano i dati, i Services agiscono come Controller e le Screens sono le Views che mostrano i dati all'utente.



                          +----------------+
                          |    main.dart   |
                          |  (Entry Point) |
                          +-------+--------+
                                  |
                +-----------------|------------------+
                |                 |                  |
    +-----------v---------+   +---v----------------+   +--------------+
    |     Screens         |   |     Services       |   |   Models     |
    |---------------------|   |--------------------|   |--------------|
    | - home_page.dart    |   | - gas_station_     |   | - gas_       |
    |   (Mappa e stazioni)|   |   service.dart     |   |   station.dart|
    |                     |   |   (Dati stazioni)  |   |   (Modello   |
    | - csv_viewer_page.  |   |                    |   |    stazione) |
    |   dart (Visualizza  |<--|-->- csv_gas_       |<--|              |
    |   file CSV)         |   |   station_service. |   | - vehicle.   |
    |                     |   |   dart (Download e |   |   dart       |
    | - custom_csv_page.  |   |   parsing CSV)     |   |   (Modello   |
    |   dart (Importa CSV)|   |                    |   |    veicolo)  |
    |                     |   | - preferences_     |<--|              |
    | - vehicles_page.    |<--|   service.dart     |   | - refueling. |
    |   dart (Gestione    |   |   (Preferenze)     |<--|   dart       |
    |   veicoli)          |   |                    |   |   (Modello   |
    |                     |   +---------+----------+   |  rifornimento)|
    | - car_stats_page.   |             |              +--------------+
    |   dart (Statistiche |             |
    |   veicoli)          |             |
    +-----------+---------+             |
                |                       |
                |                +------v-------+
                +--------------->|   Utils      |
                                |---------------|
                                | - permission_ |
                                |   handler.dart|
                                | (Gestione     |
                                |  permessi)    |
                                +--------------+