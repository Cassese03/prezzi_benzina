import UIKit
import Flutter
import CarPlay

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var carPlaySceneDelegate: Any?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registrazione per CarPlay
    if #available(iOS 14.0, *) {
      carPlaySceneDelegate = CarPlaySceneDelegate()
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Gestione della connessione CarPlay
  override func application(
    _ application: UIApplication, 
    configurationForConnecting connectingSceneSession: UISceneSession, 
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
      let scene = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
      scene.delegateClass = CarPlaySceneDelegate.self
      return scene
    }
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}