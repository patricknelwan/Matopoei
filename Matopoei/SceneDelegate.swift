import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Create LibraryViewController programmatically
        let libraryVC = LibraryViewController()
        let navigationController = UINavigationController(rootViewController: libraryVC)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
