import Foundation
import CarPlay
import Flutter

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Crea il template del menu principale
        let mainTemplate = createMainTemplate()
        interfaceController.setRootTemplate(mainTemplate, animated: true)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        // Gestisci la disconnessione
    }
    
    // Crea il template principale per CarPlay
    private func createMainTemplate() -> CPTemplate {
        // Crea gli elementi del menu
        let findGasStationsItem = CPListItem(text: "Trova Distributori", detailText: "Cerca distributori vicino a te")
        let averagePricesItem = CPListItem(text: "Prezzi Medi", detailText: "Visualizza prezzi medi dei carburanti")
        let refuelingsItem = CPListItem(text: "Rifornimenti", detailText: "Gestisci i tuoi rifornimenti")
        let vehiclesItem = CPListItem(text: "Veicoli", detailText: "Gestisci i tuoi veicoli")
        
        let section = CPListSection(items: [findGasStationsItem, averagePricesItem, refuelingsItem, vehiclesItem])
        let template = CPListTemplate(title: "CarMate", sections: [section])
        
        // Gestione dei tap
        template.delegate = self
        
        return template
    }
}

// MARK: - CPListTemplateDelegate

@available(iOS 14.0, *)
extension CarPlaySceneDelegate: CPListTemplateDelegate {
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, at indexPath: IndexPath) {
        // Gestione dei tap sugli elementi del menu
        // Mostra un alert per tutte le funzioni
        let alertTemplate = CPAlertTemplate(titleVariants: ["Funzionalità non disponibile"], 
                                          actions: [CPAlertAction(title: "OK", style: .default, handler: {})])
        interfaceController?.presentTemplate(alertTemplate, animated: true)
    }
}