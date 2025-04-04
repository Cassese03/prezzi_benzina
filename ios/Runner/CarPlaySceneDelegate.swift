import CarPlay
import Flutter

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        
        // Configura il template principale
        let mainTemplate = CPListTemplate(title: "CarMate", sections: [])
        interfaceController.setRootTemplate(mainTemplate, animated: true)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController) {
        // Gestisci la disconnessione
    }
}